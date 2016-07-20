// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package examples.baku.io.permissions;

import java.security.Permission;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by phamilton on 6/28/16.
 */

//TODO: multiple resources (Request groups)
public class PermissionRequest {

    private String id;
    private String source;
    private Map<String, Integer> permissions = new HashMap<>();
    private Map<String, String> description= new HashMap<>();

    public PermissionRequest(){}

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public Map<String, Integer> getPermissions() {
        return permissions;
    }

    public void setPermissions(Map<String, Integer> permissions) {
        this.permissions = permissions;
    }

    public Map<String, String> getDescription() {
        return description;
    }

    public void setDescription(Map<String, String> description) {
        this.description = description;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public static class Builder{
        private PermissionRequest request;

        public Builder(String path){
            this.request = new PermissionRequest();
        }
    }

}
