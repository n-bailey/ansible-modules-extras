#!powershell
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

$params = Parse-Args $args;

# Validate and set local variables from the module input.
$state = Get-Attr $params "state" $FALSE;
$valid_states = ($FALSE, 'present', 'absent');
If ($state -NotIn $valid_states) {
  Fail-Json $result "state is '$state'; must be $($valid_states)";
}

$api_key = Get-Attr $params "api_key" $FALSE;
If ($api_key -eq $FALSE) {
    Fail-Json (New-Object psobject) "missing required argument: api_key";
}

$roles = Get-Attr $params "roles" $FALSE;
If ($roles -eq $FALSE) {
    Fail-Json (New-Object psobject) "missing required argument: roles";
}

$environment_id = Get-Attr $params "environment_id" $FALSE;
If ($environment_id -eq $FALSE) {
    Fail-Json (New-Object psobject) "missing required argument: environment_id";
}

$server_uri = Get-Attr $params "server_uri" $FALSE;
If ($server_uri -eq $FALSE) {
    Fail-Json (New-Object psobject) "missing required argument: server_uri";
}

$tentacle_name = Get-Attr $params "tentacle_name" $FALSE;
If ($tentacle_name -eq $FALSE) {
    Fail-Json (New-Object psobject) "missing required argument: tentacle_name";
}

$tentacle_uri = Get-Attr $params "tentacle_uri" $FALSE;
If ($tentacle_uri -eq $FALSE) {
    Fail-Json (New-Object psobject) "missing required argument: tentacle_uri";
}

$server_protocol = Get-Attr $params "server_protocol" "https"
$valid_states = ('http', 'https');
If ($server_protocol -NotIn $valid_states) {
  Fail-Json $result "server_protocol is '$server_protocol'; must be $($valid_states)";
}

$server_port = Get-Attr $params "server_port" $FALSE;

$tentacle_protocol = Get-Attr $params "tentacle_protocol" "https"
$valid_states = ('http', 'https');
If ($tentacle_protocol -NotIn $valid_states) {
  Fail-Json $result "tentacle_protocol is '$tentacle_protocol'; must be $($valid_states)";
}
$tentacle_port = Get-Attr $params "tentacle_port" 10933;

$tentacle_home = Get-Attr $params "tentacle_home" 'C:\Program Files\Octopus Deploy\Tentacle';

# Retrieve the thumbprint from the Tentacle's certificate. 
$thumbprint_out = & ${TENTACLE_HOME}\Tentacle.exe show-thumbprint --nologo --console
If ($thumbprint_out -eq $FALSE ) {
   Fail-Json (New-Object psobject) "could not retrieve tentacle thumbprint. Check the tentacle agent is installed at $TENTACLE_PATH";
}
$tentacle_thumbprint = (Select-String -Pattern '[A-Z0-9]{40}$' -InputObject $thumbprint_out -CaseSensitive).Matches.Value

# Set up endpoint for the Octopus Deploy control server.
If ($server_port -ne $FALSE) {
  $server_endpoint = "${server_protocol}://${server_uri}:${server_port}"
}
Else {
  $server_endpoint = "${server_protocol}://${server_uri}"
}

# Prepare the target host to use the Octopus.Client library for interaction with the API.
Add-Type -Path "${tentacle_home}\Newtonsoft.Json.dll"
Add-Type -Path "${tentacle_home}\Octopus.Client.dll"

$endpoint = New-Object Octopus.Client.OctopusServerEndpoint $server_endpoint, $api_key
$repository = New-Object Octopus.Client.OctopusRepository $endpoint
$tentacle = New-Object Octopus.Client.Model.MachineResource

# Make an API call to find an existing machine with $tentacle_name so we can alter its state as needed.
$matched = $repository.machines.FindByName("$tentacle_name")

# Construct a new tentacle object from the parameters fed into the module.
# Note that the $tentacle.Roles here are Octopus Deploy roles, not the Ansible kind.
$tentacle.name = "$tentacle_name"
$tentacle.EnvironmentIds.Add("$environment_id")
$roles | Foreach-Object {
    $tentacle.Roles.Add("$_")
}
$tentacleEndpoint = New-Object Octopus.Client.Model.Endpoints.ListeningTentacleEndpointResource
$tentacle.EndPoint = $tentacleEndpoint
$tentacle.Endpoint.Uri = "${tentacle_protocol}://${tentacle_uri}:${tentacle_port}"
$tentacle.Endpoint.Thumbprint = "$tentacle_thumbprint"

# Define result object.
$result = New-Object PSObject @{
    changed = $false
    state = $state
    matched = @()
    added = @()
    deleted = @()
};

# Constructs the array to set those return values from.
function Map-TentacleState ([System.Object]$arg0) {
  return New-Object psobject @{
    thumbprint = $arg0.Endpoint.Thumbprint
    uri = $arg0.Endpoint.Uri
    id = $arg0.Id
    is_disabled = $arg0.IsDisabled
    name = $arg0.Name
    roles = $arg0.Roles
  }
}

If ($state -eq "absent" -And $matched -ne $null) {
    $repository.machines.delete($matched)
    $result.deleted = Map-TentacleState $matched
    $result.changed = $true
}

If ($state -eq "present" -And $matched -eq $null) {
    $added = $repository.machines.create($tentacle)
    $result.added = Map-TentacleState $added
    $result.changed = $true
}

# This currently returns OK and makes no changes if a tentacle with that name exists. 
# A future enhancement would be to use $repository.machines.modify($matched) to apply current state.
If ($state -eq "present" -And $matched -ne $null) {
    $result.matched = Map-TentacleState $matched
}

Exit-Json -obj $result

# vim: set ff=dos: #