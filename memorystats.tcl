#!/usr/bin/env tclsh8.6

set license {
BSD 3-clause

Copyright © 2021 Umbrellix (Ellenor Malik)

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}

set reference "#\[bg=black]#\[fg=#9ab0ff]▐#\[fg=black]#\[bg=#9ab0ff]load: %l1#\[fg=#a4a100]▐#\[bg=#a4a100]#\[fg=black]mem: %mMiO (u: %muMiO, u%: %mc%)#\[fg=#ff3934]#\[bg=#a4a100]▐#\[bg=#ff3934]#\[fg=black]"

set dp 1
set dpmult 1[string repeat 0 $dp].00
if {$dp == 0} {set dpmult 1}

if {[llength $argv] >= 1} {
	set formatstring [join $argv " "]
} {
	set formatstring $reference
	#"load: %L, memory: %M, free: %MF, free%: %MC"
}

set env(LC_ALL) C
set sysctls [exec sysctl vm.loadavg hw.pagesize vm.stats.vm.v_page_count vm.stats.vm.v_free_count]

set sysctls [split $sysctls "\r\n"]
set ctls [list]

foreach {ctl} $sysctls {
	set ctl [split $ctl ": "]
	set ctlvo [lrange $ctl 1 end]
	set ctlv [list]
	foreach {v} $ctlvo {
		if {$v != {} && $v != "{" && $v != "}"} {lappend ctlv $v}
	}
	dict set ctls [lindex $ctl 0] $ctlv
}

set lavgs [dict get $ctls vm.loadavg]
set pgsiz [dict get $ctls hw.pagesize]
set vpgct [dict get $ctls vm.stats.vm.v_page_count]
set vfrct [dict get $ctls vm.stats.vm.v_free_count]

set vmtot [expr {($vpgct * $pgsiz) / (1024.0*1024.0)}]
set vmfree [expr {($vfrct * $pgsiz) / (1024.0*1024.0)}]
set vmused [expr {$vmtot - $vmfree}]
set vmusec [expr {(($vmtot - $vmfree) / $vmtot) * 100.0}]
set vmfrec [expr {($vmfree / $vmtot) * 100.0}]

set map [list %l1 [lindex $lavgs 0] \
	%L1	[lindex $lavgs 0] \
	%l2 [lindex $lavgs 1] \
	%L2 [lindex $lavgs 1] \
	%l3 [lindex $lavgs 2] \
	%L3 [lindex $lavgs 2] \
	%l $lavgs \
	%L $lavgs \
	%mf [expr {round(($vmfree * $dpmult)) / $dpmult}] \
	%MF [expr {round(($vmfree * $dpmult)) / $dpmult}] \
	%mu [expr {round(($vmused * $dpmult)) / $dpmult}] \
	%MU [expr {round(($vmused * $dpmult)) / $dpmult}] \
	%mc [expr {round(($vmusec * $dpmult)) / $dpmult}] \
	%MC [expr {round(($vmusec * $dpmult)) / $dpmult}] \
	%fc [expr {round(($vmfrec * $dpmult)) / $dpmult}] \
	%FC [expr {round(($vmfrec * $dpmult)) / $dpmult}] \
	%m [expr {round(($vmtot * $dpmult)) / $dpmult}] \
	%M [expr {round(($vmtot * $dpmult)) / $dpmult}] \
	=mf $vmfree \
	=MF $vmfree \
	=mu $vmused \
	=MU $vmused \
	=mc $vmusec \
	=MC $vmusec \
	=fc $vmfrec \
	=FC $vmfrec \
	=m $vmtot \
	=M $vmtot \
	]
puts -nonewline stdout [string map $map $formatstring]
flush stdout

#LC_ALL=C sysctl vm.loadavg hw.pagesize vm.stats.vm.v_page_count vm.stats.vm.v_free_count
