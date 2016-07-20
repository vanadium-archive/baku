// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions.util;

import android.app.Fragment;
import android.content.Context;
import android.os.Bundle;

/**
 * Created by phamilton on 6/26/16.
 *
 * Fragment that requires the binding context to implement an event handler.
 */
public class EventFragment extends Fragment{

    EventFragmentListener mListener;

    public interface EventFragmentListener{
        boolean onFragmentEvent(int action, Bundle args, EventFragment fragment);
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        try {
            mListener = (EventFragmentListener) context;
        } catch (ClassCastException e) {
            throw new ClassCastException(context.toString() + " must implement EventFragmentListener");
        }
    }

    public boolean onEvent(int action, Bundle args){
        if(mListener == null)
            return false;
        return mListener.onFragmentEvent(action, args, this);
    }
}
