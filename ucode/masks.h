#pragma once

#include <stddef.h>
#include <string.h>

#define OP_RAW      (1 << 15)
#define OP_END      (1 << 4)

#define RAW_WRITE   (1 << 14)
#define RAW_RMASK(x)(((x) & 0b11) << 12)
#define RAW_ALUIMM  (1 << 11)
#define RAW_AMASK(x)(((x) & 0b1111) << 7)
#define RAW_WMASK(x)(((x) & 0b11) << 5)
#define RAW_FLAGS   (1 << 3)

static inline unsigned int get_write_id(char* id) {
    if(id == NULL) return 0;
    if(!strcasecmp(id, "mar"))  return 0b00;
    if(!strcasecmp(id, "mdr"))  return 0b01;
    if(!strcasecmp(id, "rs"))   return 0b10;
    if(!strcasecmp(id, "rd"))   return 0b11;
    return -1;
}

static inline unsigned int get_read_id(char* id) {
    if(id == NULL) return 0;
    if(!strcasecmp(id, "imm"))  return 0b00;
    if(!strcasecmp(id, "mdr"))  return 0b01;
    if(!strcasecmp(id, "rs"))   return 0b10;
    if(!strcasecmp(id, "rd"))   return 0b11;
    return -1;
}

static inline int get_alu_id(char* id) {
    if(!strcasecmp(id, "op"))  return 0;
    if(!strcasecmp(id, "mov"))  return 0b0000;
    if(!strcasecmp(id, "add"))  return 0b0001;
    if(!strcasecmp(id, "sub"))  return 0b0010;
    if(!strcasecmp(id, "and"))  return 0b0100;
    if(!strcasecmp(id, "or" ))  return 0b0101;
    if(!strcasecmp(id, "xor"))  return 0b0110;
    if(!strcasecmp(id, "shl"))  return 0b0111;
    if(!strcasecmp(id, "shr"))  return 0b1000;
    if(!strcasecmp(id, "latch")) return 0b1100;
    return -1;
}
