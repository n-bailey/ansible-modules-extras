#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# (c) 2016, Nikki Bailey <nikobelia@gmail.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

DOCUMENTATION = '''
---
module: win_octopus_register
short_description: Registers an Tentacle client with the Octopus server.
version_added: "2.1"
options:
description:
     - Registers an Tentacle client with the Octopus server.
     - This requires a Tentacle version of 3.0 or above to be installed on the target host already.
     - It must be running, and configured with a thumbprint.
notes:
author: "Nikki Bailey (@n-bailey)"
options:
    state:
        description:
            - State of the Tentacle agent.
        required: true
        choices:
            - present
            - absent
    api_key:
        description:
            - API key for the Octopus server you are registering or deregistering the Tentacle with.
            - This is sensitive information. Use `no_log: true` to keep it hidden as appropriate.
        required: true
    role:
        description:
            - Role or list of roles which the Tentacle will be registered with.
            - Must already exist on the target Octopus server.
        required: true
    environment_id:
        description:
            - Environment to add the Tentacle to, as a string. Must already exist on the Octopus server.
        required: true
    tentacle_name:
        description:
            - Display name to register the Tentacle under.
        required: true
    server_uri:
        description:
            - IP address or hostname of the Octopus Deploy server. Do not specify the protocol (http or https).
        required: true
    server_protocol:
        description:
            - Protocol used to communicate with the server through the API
        required: false
        default: https
        choices:
            - http
            - https
    server_port:
        description:
            - Port on which to communicate with the Tentacle API. Optional, not generally needed.
        required: false
        default: null
    tentacle_uri:
        description:
            - IP address or hostname of the Tentacle.
        required: true
    tentacle_protocol:
        description:
            - Protocol used to communicate with the server through the API.
        required: false
        default: https
        choices:
            - http
            - https
    tentacle_port:
        description:
            - Port on which the server should communicate with the Tentacle.
        required: false
        default: 10933
    tentacle_home:
        description:
            - Parent directory of the tentacle executable.
            - This should contain 'Octopus.Client.dll' and 'Newtonsoft.Json.dll'.
        required: false
        default: 'C:\Program Files\Octopus Deploy\Tentacle'
'''

EXAMPLES = '''
- name: Deregister this host from the Octopus server.
  win_octopus_register:
    state: absent
    role: web
    api_key: "{{ vaulted_octopus_api_key }}"
    environment_id: "Environment-22"
    octopus_server: "deploy.example.com"
    tentacle_uri: "{{ inventory_hostname }}"
    tentacle_name: "{{ inventory_hostname_short }}"
  register: win_octopus_register_return

- name: And re-register it with a different Octopus server on another port, using plaintext.
  win_octopus_register:
    state: present
    role: web
    api_key: "{{ vaulted_octopus_api_key }}"
    environment_id: "Environment-3"
    server_uri: "different.example.com"
    tentacle_uri: "{{ inventory_hostname }}"
    tentacle_name: "{{ inventory_hostname_short }}"
    tentacle_port: 10943
    tentacle_protocol: "http"
    server_protocol: "http"
  when: win_octopus_register.changed == True

- name: Register a client with multiple roles.
  ilmn_win_octopus_register:
    state: absent
    role: [ api, database ]
    api_key: "{{ vaulted_octopus_api_key }}"
    environment_id: "Environment-1"
    octopus_server: "another.example.com"
    tentacle_uri: "{{ inventory_hostname }}"
    tentacle_name: "{{ inventory_hostname }}"
'''
