#include "VSingle_CycleRV.h"
#include "verilated.h"
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <elf.h>
#include <fstream>
#include <iostream>
#include <unordered_map>
#include <vector>

static std::unordered_map<uint32_t, uint8_t> mem;

static inline uint8_t read_u8(uint32_t addr) {
    auto it = mem.find(addr);
    return (it != mem.end()) ? it->second : 0;
}
static inline uint16_t read_u16(uint32_t addr) {
    return (uint16_t)read_u8(addr) | ((uint16_t)read_u8(addr + 1) << 8);
}
static inline uint32_t read_u32(uint32_t addr) {
    return (uint32_t)read_u8(addr) |
           ((uint32_t)read_u8(addr + 1) << 8) |
           ((uint32_t)read_u8(addr + 2) << 16) |
           ((uint32_t)read_u8(addr + 3) << 24);
}
static inline void write_u8(uint32_t addr, uint8_t val) { mem[addr] = val; }
static inline void write_u16(uint32_t addr, uint16_t val) {
    write_u8(addr, val & 0xFF);
    write_u8(addr + 1, (val >> 8) & 0xFF);
}
static inline void write_u32(uint32_t addr, uint32_t val) {
    write_u8(addr, val & 0xFF);
    write_u8(addr + 1, (val >> 8) & 0xFF);
    write_u8(addr + 2, (val >> 16) & 0xFF);
    write_u8(addr + 3, (val >> 24) & 0xFF);
}

static bool load_elf(const char *path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) return false;
    std::vector<uint8_t> buf((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    if (buf.size() < sizeof(Elf32_Ehdr)) return false;
    const Elf32_Ehdr *eh = reinterpret_cast<const Elf32_Ehdr *>(buf.data());
    if (eh->e_ident[EI_MAG0] != ELFMAG0 || eh->e_ident[EI_MAG1] != ELFMAG1 ||
        eh->e_ident[EI_MAG2] != ELFMAG2 || eh->e_ident[EI_MAG3] != ELFMAG3) return false;
    const Elf32_Phdr *ph = reinterpret_cast<const Elf32_Phdr *>(buf.data() + eh->e_phoff);
    for (int i = 0; i < eh->e_phnum; i++) {
        if (ph[i].p_type != PT_LOAD) continue;
        uint32_t paddr = ph[i].p_paddr ? ph[i].p_paddr : ph[i].p_vaddr;
        for (uint32_t j = 0; j < ph[i].p_filesz; j++)
            mem[paddr + j] = buf[ph[i].p_offset + j];
        for (uint32_t j = ph[i].p_filesz; j < ph[i].p_memsz; j++)
            mem[paddr + j] = 0;
    }
    return true;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    if (argc < 6) {
        std::cerr << "Usage: " << argv[0] << " <elf> <sig_out> <begin_hex> <end_hex> <tohost_hex> [max_cycles]\n";
        return 1;
    }
    const char *elf_path = argv[1];
    const char *sig_path = argv[2];
    uint32_t begin_sig = std::strtoul(argv[3], nullptr, 16);
    uint32_t end_sig   = std::strtoul(argv[4], nullptr, 16);
    uint32_t tohost    = std::strtoul(argv[5], nullptr, 16);
    uint64_t max_cycles = (argc >= 7) ? std::strtoull(argv[6], nullptr, 10) : 2000000ULL;

    if (!load_elf(elf_path)) {
        std::cerr << "Failed to load ELF: " << elf_path << "\n";
        return 1;
    }

    VSingle_CycleRV *top = new VSingle_CycleRV;
    top->clk = 0; top->reset = 1; top->stall = 0;
    top->instruction = 0x00000013; top->mem_out = 0;
    top->eval();
    top->clk = 1; top->eval();
    top->clk = 0; top->reset = 0; top->eval();

    bool done = false;
    for (uint64_t cyc = 0; cyc < max_cycles && !done; cyc++) {
        top->clk = 0;
        top->instruction = read_u32(top->address);
        top->eval();

        uint32_t addr = top->alu_out;
        switch (top->fn3) {
            case 0: top->mem_out = (uint32_t)(int32_t)(int8_t)read_u8(addr); break;
            case 1: top->mem_out = (uint32_t)(int32_t)(int16_t)read_u16(addr); break;
            case 2: top->mem_out = read_u32(addr); break;
            case 4: top->mem_out = (uint32_t)read_u8(addr); break;
            case 5: top->mem_out = (uint32_t)read_u16(addr); break;
            default: top->mem_out = read_u32(addr); break;
        }
        top->eval();

        if (top->mem_write) {
            if (addr == tohost && top->rs2_data != 0) {
                done = true;
            } else {
                if (top->fn3 == 0) write_u8(addr, top->rs2_data & 0xFF);
                else if (top->fn3 == 1) write_u16(addr, top->rs2_data & 0xFFFF);
                else if (top->fn3 == 2) write_u32(addr, top->rs2_data);
            }
        }

        top->clk = 1;
        top->eval();
    }

    FILE *fp = std::fopen(sig_path, "w");
    for (uint32_t a = begin_sig; a < end_sig; a += 4)
        std::fprintf(fp, "%08x\n", read_u32(a));
    std::fclose(fp);

    delete top;
    return done ? 0 : 2;
}
