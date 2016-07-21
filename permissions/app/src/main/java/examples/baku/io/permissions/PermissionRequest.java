// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ServerValue;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by phamilton on 6/28/16.
 */

//TODO: multiple resources (Request groups)
public class PermissionRequest {

    public static final String EXTRA_TITLE = "title";

    private String id;
    private String path;
    private String source;
    private int permissions;
    private int flags;
    private Map<String, String> extras = new HashMap<>();
    private long timeStamp;

    public PermissionRequest() {
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }


    public Map<String, String> getExtras() {
        return extras;
    }

    public void setExtras(Map<String, String> extras) {
        this.extras = extras;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public int getPermissions() {
        return permissions;
    }

    public void setPermissions(int permissions) {
        this.permissions = permissions;
    }

    public int getFlags() {
        return flags;
    }

    public void setFlags(int flags) {
        this.flags = flags;
    }

    public Map<String, String> getTimeStamp() {
        return ServerValue.TIMESTAMP;
    }

    public void setTimeStamp(long timeStamp) {
        this.timeStamp = timeStamp;
    }

    //accept suggested permissions
    public void grant(PermissionManager manager) {
        manager.grantRequest(this);
    }

    public void finish(PermissionManager manager) {
        manager.finishRequest(id);
    }

    public static class Builder {
        private PermissionRequest request;
        private DatabaseReference ref;

        public Builder(DatabaseReference ref, String path, String source) {
            this.ref = ref;
            this.request = new PermissionRequest();
            request.setId(ref.getKey());
            request.setPath(path);
            request.setSource(source);
        }

        public PermissionRequest.Builder putExtra(String key, String value) {
            this.request.extras.put(key, value);
            return this;
        }


        public PermissionRequest.Builder setPermissions(int suggested) {
            request.setPermissions(suggested);
            return this;
        }

        public int getFlags() {
            return request.getFlags();
        }

        public PermissionRequest.Builder setFlags(int flags) {
            this.request.flags = flags;
            return this;
        }

        public void cancel() {
            this.ref.removeValue();
        }

        public PermissionRequest udpate() {
            //TODO: check valid
            this.ref.setValue(request);
            return request;
        }

    }

}
