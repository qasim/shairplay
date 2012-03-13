#ifndef RAOP_RTP_H
#define RAOP_RTP_H

/* For raop_callbacks_t */
#include "raop.h"
#include "logger.h"

#define RAOP_AESKEY_LEN 16
#define RAOP_AESIV_LEN  16
#define RAOP_PACKET_LEN 32768

typedef struct raop_rtp_s raop_rtp_t;

raop_rtp_t *raop_rtp_init(logger_t *logger, raop_callbacks_t *callbacks, const char *fmtp,
                          const unsigned char *aeskey, const unsigned char *aesiv);
void raop_rtp_start(raop_rtp_t *raop_rtp, int use_udp, unsigned short control_rport, unsigned short timing_rport,
                    unsigned short *control_lport, unsigned short *timing_lport, unsigned short *data_lport);
void raop_rtp_set_volume(raop_rtp_t *raop_rtp, float volume);
void raop_rtp_flush(raop_rtp_t *raop_rtp, int next_seq);
void raop_rtp_stop(raop_rtp_t *raop_rtp);
void raop_rtp_destroy(raop_rtp_t *raop_rtp);

#endif