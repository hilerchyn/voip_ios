/*
 *  Copyright 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

// This file contains interfaces for RtpSenders
// http://w3c.github.io/webrtc-pc/#rtcrtpsender-interface

#ifndef WEBRTC_API_RTPSENDERINTERFACE_H_
#define WEBRTC_API_RTPSENDERINTERFACE_H_

#include <string>

#include "webrtc/api/mediastreaminterface.h"
#include "webrtc/api/proxy.h"
#include "webrtc/base/refcount.h"
#include "webrtc/base/scoped_ref_ptr.h"
#include "webrtc/pc/mediasession.h"

namespace webrtc {

class RtpSenderInterface : public rtc::RefCountInterface {
 public:
  // Returns true if successful in setting the track.
  // Fails if an audio track is set on a video RtpSender, or vice-versa.
  virtual bool SetTrack(MediaStreamTrackInterface* track) = 0;
  virtual rtc::scoped_refptr<MediaStreamTrackInterface> track() const = 0;

  // Used to set the SSRC of the sender, once a local description has been set.
  // If |ssrc| is 0, this indiates that the sender should disconnect from the
  // underlying transport (this occurs if the sender isn't seen in a local
  // description).
  virtual void SetSsrc(uint32_t ssrc) = 0;
  virtual uint32_t ssrc() const = 0;

  // Audio or video sender?
  virtual cricket::MediaType media_type() const = 0;

  // Not to be confused with "mid", this is a field we can temporarily use
  // to uniquely identify a receiver until we implement Unified Plan SDP.
  virtual std::string id() const = 0;

  // TODO(deadbeef): Support one sender having multiple stream ids.
  virtual void set_stream_id(const std::string& stream_id) = 0;
  virtual std::string stream_id() const = 0;

  virtual void Stop() = 0;

 protected:
  virtual ~RtpSenderInterface() {}
};

// Define proxy for RtpSenderInterface.
BEGIN_PROXY_MAP(RtpSender)
PROXY_METHOD1(bool, SetTrack, MediaStreamTrackInterface*)
PROXY_CONSTMETHOD0(rtc::scoped_refptr<MediaStreamTrackInterface>, track)
PROXY_METHOD1(void, SetSsrc, uint32_t)
PROXY_CONSTMETHOD0(uint32_t, ssrc)
PROXY_CONSTMETHOD0(cricket::MediaType, media_type)
PROXY_CONSTMETHOD0(std::string, id)
PROXY_METHOD1(void, set_stream_id, const std::string&)
PROXY_CONSTMETHOD0(std::string, stream_id)
PROXY_METHOD0(void, Stop)
END_PROXY()

}  // namespace webrtc

#endif  // WEBRTC_API_RTPSENDERINTERFACE_H_
