//
//  VoIPDataSyncHandler.swift
//  Pods
//
//  Created by vincepzhang on 2025/9/22.
//

import RTCRoomEngine
import TUICore

protocol VoIPDataSyncHandlerDelegate: NSObject {
    func callMethodVoipChangeMute(mute: Bool)
    func callMethodVoipChangeAudioPlaybackDevice(audioPlaybackDevice: TUIAudioPlaybackDevice)
    func callMethodVoipHangup()
    func callMethodVoipAccept()
}

class VoIPDataSyncHandler: NSObject, TUIServiceProtocol, TUICallObserver {
    let TUICore_TUICore_TUIVoIPExtensionNotify_MuteSubKey_IsMuteKey = "TUICore_TUICore_TUIVoIPExtensionNotify_MuteSubKey_IsMuteKey"
    let TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_InviterIdKey = "TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_InviterIdKey"
    let TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_InviteeListKey = "TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_InviteeListKey"
    let TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_GroupIDKey = "TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_GroupIDKey"
    let TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_MediaTypeKey = "TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_MediaTypeKey"

    let TUICore_TUICallingService_SetIsMicMuteMethod_IsMicMute = "TUICore_TUICallingService_SetIsMicMuteMethod_IsMicMute"
    let TUICore_TUICallingService_SetAudioPlaybackDevice_AudioPlaybackDevice = "TUICore_TUICallingService_SetAudioPlaybackDevice_AudioPlaybackDevice"
    let TUICore_TUICallingService_ShowCallingViewMethod_UserIDsKey = "TUICore_TUICallingService_ShowCallingViewMethod_UserIDsKey"
    let TUICore_TUICallingService_ShowCallingViewMethod_CallTypeKey = "TUICore_TUICallingService_ShowCallingViewMethod_CallTypeKey"
    
    weak var voipDataSyncHandlerDelegate: VoIPDataSyncHandlerDelegate?
    
    override init() {
        super.init()
        TUICallEngine.createInstance().addObserver(self)
    }
    
    func onCall(_ method: String, param: [AnyHashable : Any]) {
        if method == TUICore_TUICallingService_SetAudioPlaybackDeviceMethod {
            guard let audioPlaybackDevice = param[TUICore_TUICallingService_SetAudioPlaybackDevice_AudioPlaybackDevice]
                    as? TUIAudioPlaybackDevice else { return }
            if self.voipDataSyncHandlerDelegate != nil && ((self.voipDataSyncHandlerDelegate?.responds(to: Selector(("callMethodVoipChangeAudioPlaybackDevice")))) != nil) {
                self.voipDataSyncHandlerDelegate?.callMethodVoipChangeAudioPlaybackDevice(audioPlaybackDevice: audioPlaybackDevice)
            }
        } else if method == TUICore_TUICallingService_SetIsMicMuteMethod {
            guard let isMicMute = param[TUICore_TUICallingService_SetIsMicMuteMethod_IsMicMute]
                    as? Bool else { return }
            if self.voipDataSyncHandlerDelegate != nil && ((self.voipDataSyncHandlerDelegate?.responds(to: Selector(("callMethodVoipChangeMute")))) != nil) {
                self.voipDataSyncHandlerDelegate?.callMethodVoipChangeMute(mute: isMicMute)
            }
        }
        
        else if method == TUICore_TUICallingService_HangupMethod {
            if self.voipDataSyncHandlerDelegate != nil && ((self.voipDataSyncHandlerDelegate?.responds(to: Selector(("callMethodVoipHangup")))) != nil) {
                self.voipDataSyncHandlerDelegate?.callMethodVoipHangup()
            }
        } else if method == TUICore_TUICallingService_AcceptMethod {
            if self.voipDataSyncHandlerDelegate != nil && ((self.voipDataSyncHandlerDelegate?.responds(to: Selector(("callMethodVoipAccept")))) != nil) {
                self.voipDataSyncHandlerDelegate?.callMethodVoipAccept()
            }
        }
    }
    
    func setVoIPMute(_ mute: Bool) {
        TUICore.notifyEvent(TUICore_TUIVoIPExtensionNotify,
                            subKey: TUICore_TUICore_TUIVoIPExtensionNotify_MuteSubKey,
                            object: nil,
                            param: [TUICore_TUICore_TUIVoIPExtensionNotify_MuteSubKey_IsMuteKey: mute])
    }
    
    func closeVoIP() {
        TUICore.notifyEvent(TUICore_TUIVoIPExtensionNotify,
                            subKey: TUICore_TUICore_TUIVoIPExtensionNotify_EndSubKey,
                            object: nil,
                            param: nil)
    }
    
    func connectVoIP() {
        TUICore.notifyEvent(TUICore_TUIVoIPExtensionNotify,
                            subKey: TUICore_TUICore_TUIVoIPExtensionNotify_ConnectedKey,
                            object: nil,
                            param: nil)
    }
    
    func updateVoIPInfo(callerId: String, calleeList: [String], groupId: String, mediaType: TUICallMediaType) {
        TUICore.notifyEvent(TUICore_TUIVoIPExtensionNotify,
                            subKey: TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey,
                            object: nil,
                            param: [TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_InviterIdKey: callerId,
                                    TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_InviteeListKey: calleeList,
                                    TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_GroupIDKey: groupId,
                                    TUICore_TUICore_TUIVoIPExtensionNotify_UpdateInfoSubKey_MediaTypeKey: mediaType.rawValue])
    }
    
    func onCallReceived(callerId: String, calleeIdList: [String], groupId: String?, callMediaType: TUICallMediaType, userData: String?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.updateVoIPInfo(callerId: callerId, calleeList: calleeIdList, groupId: groupId ?? "", mediaType: callMediaType)
        }
    }
    
    func onCallCancelled(callerId: String) {
        closeVoIP()
    }
    
    func onCallEnd(roomId: TUIRoomId, callMediaType: TUICallMediaType, callRole: TUICallRole, totalTime: Float) {
        closeVoIP()
    }
    
    func onCallBegin(roomId: TUIRoomId, callMediaType: TUICallMediaType, callRole: TUICallRole) {
        connectVoIP()
    }
}
