//
//  CallingVibrator.swift
//  Pods
//
//  Created by iveshe on 2025/10/13.
//

import AudioToolbox

class CallingVibrator {

    private static var isVibrating = false

    static func startVibration() {
        isVibrating = true
        DispatchQueue.global().async {
            while isVibrating {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }

    static func stopVibration() {
        isVibrating = false
    }
}

