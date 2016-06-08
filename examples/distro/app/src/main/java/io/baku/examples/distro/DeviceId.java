// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.baku.examples.distro;

import android.content.Context;
import android.provider.Settings;

import lombok.experimental.UtilityClass;

@UtilityClass
public class DeviceId {
    public static String get(final Context context) {
        return Settings.Secure.getString(
                context.getContentResolver(),
                Settings.Secure.ANDROID_ID);
    }
}
