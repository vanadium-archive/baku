// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.util;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.Icon;

import com.joanzapata.iconify.IconDrawable;

import java.util.Set;

/**
 * Created by phamilton on 7/20/16.
 */
public class Utils {

    private static final int defaultIconSize = 50;  //this number was chosen at random

    public static Icon iconFromDrawable(Drawable drawable) {
        int width = drawable.getIntrinsicWidth();
        int height = drawable.getIntrinsicHeight();
        if (width <= 0 || height <= 0) {
            width = defaultIconSize;
            height = defaultIconSize;
        }
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);

        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);
        return Icon.createWithBitmap(bitmap);
    }


    //path keys are separated by '/' delimiter: a/b/c/...
    public static String getNearestCommonAncestor(String path, Set<String> ancestors) {
        if (path == null || ancestors.contains(path)) {
            return path;
        }
        if (path.startsWith("/")) {
            throw new IllegalArgumentException("Path can't start with /");
        }
        String subpath = path;
        int index;
        while ((index = subpath.lastIndexOf("/")) != -1) {
            subpath = subpath.substring(0, index);
            if (ancestors.contains(subpath)) {
                return subpath;
            }
        }

        return null;
    }
}
