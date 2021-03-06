/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#ifndef IM_UTIL_H
#define IM_UTIL_H

#ifdef __cplusplus
extern "C" {
#endif
void voip_writeInt32(int32_t v, void *p);
int32_t voip_readInt32(const void *p);

void voip_writeInt64(int64_t v, void *p);
int64_t voip_readInt64(const void *p);

void voip_writeInt16(int16_t v, void *p);
int16_t voip_readInt16(const void *p);

int voip_lookupAddr(const char *host, int port, struct sockaddr_in *addr);


int voip_sock_nonblock(int fd, int set);
int voip_write_data(int fd, uint8_t *bytes, int len);
#ifdef __cplusplus
}
#endif

#endif
