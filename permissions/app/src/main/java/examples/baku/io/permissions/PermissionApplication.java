// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions;

import android.app.Application;

import com.joanzapata.iconify.Iconify;
import com.joanzapata.iconify.fonts.MaterialModule;

/**
 * Created by phamilton on 7/20/16.
 */
public class PermissionApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        //Add icons
        Iconify.with(new MaterialModule());
    }
}
