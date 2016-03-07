// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.v.baku.hellobaku;

import android.app.Activity;
import android.os.Bundle;
import android.widget.EditText;
import android.widget.TextView;

import io.v.baku.toolkit.VAndroidContextMixin;
import io.v.baku.toolkit.VAndroidContextTrait;
import io.v.baku.toolkit.bind.BindingBuilder;
import io.v.rx.syncbase.RxAndroidSyncbase;
import io.v.rx.syncbase.RxDb;
import io.v.rx.syncbase.RxTable;
import io.v.rx.syncbase.UserSyncgroup;
import rx.Subscription;

public class HelloActivityALaCarte extends Activity {
    private RxAndroidSyncbase mSb;
    private Subscription mActivityDataBindings;

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hello);

        final VAndroidContextTrait<HelloActivityALaCarte> vActivity =
                VAndroidContextMixin.withDefaults(this, savedInstanceState);

        mSb = new RxAndroidSyncbase(vActivity);
        // Operate on Syncbase io.v.baku.hellobaku/db/t
        final RxDb db = mSb.rxApp(getPackageName()).rxDb("db");
        final RxTable t = db.rxTable("t");

        final TextView txtOutput = (TextView) findViewById(R.id.displayTextView);

        // We want this data binding to share the lifecycle of the Activity from onCreate to
        // onDestroy, so keep track of its Subscription and unsubscribe in onDestroy.
        final BindingBuilder builder = new BindingBuilder()
                .activity(vActivity)
                .rxTable(db.rxTable("t"));

        mActivityDataBindings = builder.getAllBindings();

        // Binds the Syncbase row named "message" to displayTextView, a.k.a. txtOutput.
        builder.onKey("message")
                .bindTo(txtOutput);

        final EditText txtInput = (EditText) findViewById(R.id.inputEditText);
        findViewById(R.id.actionButton).setOnClickListener(bn -> {
            // Setting the text on txtOutput will update the "message" Syncbase row via the data
            // binding we established above.
            txtOutput.setText(txtInput.getText());
            txtInput.setText("");
        });

        UserSyncgroup.builder()
                .activity(vActivity)
                .db(db)
                .prefix("t")
                .sgSuffix("myGlobalUserSyncgroup")
                .buildCloud()
                .join();
    }

    @Override
    protected void onDestroy() {
        mActivityDataBindings.unsubscribe();
        mSb.close();
        super.onDestroy();
    }
}
