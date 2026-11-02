# ETH01 wire contract v1

One TCP client at a time. TCP is a byte stream. No native C structs go on wire.
All integers are unsigned, network byte order. Header is exactly 32 bytes:

| Offset | Bytes | Meaning |
|---|---:|---|
| 0 | 4 | ASCII `E01T` |
| 4 | 1 | Version 1 |
| 5 | 1 | Type |
| 6 | 2 | Reserved, zero |
| 8 | 4 | Nonzero transfer ID, constant for this connection |
| 12 | 4 | Nonzero strictly increasing sequence, no wrap within a session |
| 16 | 4 | Bulk total length; otherwise zero |
| 20 | 4 | Bulk byte offset; otherwise zero |
| 24 | 4 | Payload length 0..4096 |
| 28 | 4 | IEEE CRC32 of payload, initial/final xor all ones (Python zlib) |

Replies copy transfer/seq/total/offset, set type `request|0x80`. Type255 carries
a uint32 error. Bad envelope/CRC/identity/order closes the connection; valid
envelope with invalid operation produces error. No resynchronization or retry.

| Type | Request / reply |
|---|---|
| 1 ECHO | 0..256 bytes unchanged (transport smoke test only) |
| 2 MODEL | 0..256 bytes; reply uint32 processing count then generated-model XOR bytes |
| 3 BEGIN | no payload, total1..33554432, offset0; discard any old session transfer |
| 4 WRITE | contiguous offset, nonempty <=4096 bytes, matching total; empty ACK |
| 6 FINISH | offset0, payload whole-buffer uint32 CRC; requires all bytes written; reply CRC and seal |
| 5 READ | no payload, offset<sealed total; reply min(4096,total-offset) bytes |
| 7 STATUS | no payload; reply uint32 build ID, initial negotiated Mbps, cache flags, model count |

Cache flag1 means I-cache ON/D-cache OFF. Speed is initial negotiated speed,
not a continuous link monitor. Model counter is lifetime processing count in
this boot; an abandoned response is discarded at disconnect, count is retained.
No path, address, register, control command or arbitrary-memory operation exists.

Host and ARM share `eth_protocol.c`, `eth_service.c`, `eth_model_if.c` and the
actual generated model C. The model has 256-byte ports, uint16 len, bool valid,
uint32 seq, bool TxReady; outputs reply/len/valid/seq/count/uint8 status.
Model statuses: 0 idle,1 accepted,2 held pending,3 length rejected.
Queue API: 0 OK,1 empty,2 full,3 range,4 disconnected. All copies are bounded;
no wait for ACK. A held model output persists until TxReady. NetService runs
separately from the model, outside any future 100µs Runtime step.

TCP receive callbacks only copy a complete pbuf chain into an 8192-byte FIFO.
On ERR_MEM they retain no bytes and do not free/ack pbuf; lwIP retries it.
Receive-window credit is returned only after complete-frame consumption, so
unacknowledged bytes are bounded by FIFO capacity (including reassembled chains).
Parser commits a command once. TX uses TCP_WRITE_FLAG_COPY, <=1460-byte slices,
retains offsets on ERR_MEM, and consumes only after tcp_write accepts bytes.
An accepted command's output remains bounded while the receiver is slow.
Disconnect discards partial frames, unsent replies and test-buffer validity.
Reconnect starts a new session; it cannot continue an abandoned transfer.
FIN half-close drains accepted complete commands/replies before tcp_close;
an incomplete final frame or RST abandons the session explicitly.
