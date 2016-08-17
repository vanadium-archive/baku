// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions;

import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.drawable.Icon;
import android.service.chooser.ChooserTarget;
import android.service.chooser.ChooserTargetService;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by phamilton on 8/16/16.
 */
public class PermissionTargetService extends ChooserTargetService {

    @Override
    public List<ChooserTarget> onGetChooserTargets(ComponentName targetActivityName, IntentFilter matchedFilter) {
        final List<ChooserTarget> targets = new ArrayList<>();

        final String title = "Cast";
        final Icon icon = Icon.createWithResource(this, R.mipmap.ic_launcher);
        final float score = 1.0f;

        Intent intent = new Intent(PermissionService.ACTION_SHARE_EVENT);
        sendBroadcast(intent);

        targets.add(new ChooserTarget(title, icon, score, targetActivityName, null));
        return targets;
    }

}
