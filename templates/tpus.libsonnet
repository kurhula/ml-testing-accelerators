# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

local base = import 'base.libsonnet';

{
  TpuSpec:: base.BaseAccelerator {
    local tpu = self,

    name: "v%(version)d-%(size)d" % tpu,
    type: "tpu",
    version: error "Must override `version`",
    size: error "Must override `size`",
    replicas: tpu.size / 8, # Each TPU replica has 8 cores

    PodTemplate(tpuSettings):: {
      metadata: {
        annotations: {
          "tf-version.cloud-tpus.google.com": tpuSettings.softwareVersion,
        },
      },
      spec+: {
        containerMap+: {
          train+: {
            resources+: {
              local preemptiblePrefix = 
                if tpuSettings.preemptible then
                  "preemptible-"
                else
                  "",
              local resourceName = "cloud-tpus.google.com/%sv%s" % [preemptiblePrefix, tpu.version],

              limits+: { [resourceName]: tpu.size },
            },
          },
        },
        nodeSelector+:
          if tpuSettings.requireTpuAvailableLabel then
            { "tpu-available": "true" }
          else
            { },
      },
    },
  },

  v2_8: self.TpuSpec { version: 2, size: 8 },
  v3_8: self.TpuSpec { version: 3, size: 8 },
  v2_32: self.TpuSpec { version: 2, size: 32 },
  v3_32: self.TpuSpec { version: 3, size: 32 },
}
