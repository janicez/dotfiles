#!/usr/bin/env tclsh8.6

set license {
BSD 3-clause

Copyright © 2017 Umbrellix (Ellenor Malik)

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}

if {[llength $argv] >= 3} {
	#Both device and mode
	set mode [lindex $argv 0]
	set iface [lindex $argv 1]
	set sibin [lindex $argv 2]
}

if {[llength $argv] == 2} {
	#Both device and mode
	set mode [lindex $argv 0]
	set iface [lindex $argv 1]
	set sibin 0
}

if {[llength $argv] == 1} {
	# Mode
	set mode [lindex $argv 0]
	set iface eth0
	set sibin 0
}

if {[llength $argv] == 0} {
	set mode human
	set iface eth0
	set sibin 0
}

set netstat1 [exec netstat -I $iface -b -n]

after 500
set netstat2 [exec netstat -I $iface -b -n]

set netstatlines1 [split $netstat1 "\r\n"]
set netstatlines2 [split $netstat2 "\r\n"]

set line1 [split [lindex $netstatlines1 1] "\t "]
set line2 [split [lindex $netstatlines2 1] "\t "]

set lines1 [list]
set lines2 [list]

foreach entry $line1 {
 if {$entry != {}} {lappend lines1 $entry}
}

foreach entry $line2 {
 if {$entry != {}} {lappend lines2 $entry}
}

set ibytes1 [lindex $lines1 7]
set obytes1 [lindex $lines1 10]

set ibytes2 [lindex $lines2 7]
set obytes2 [lindex $lines2 10]

set ioqs [expr {$ibytes2 - $ibytes1}]
set ooqs [expr {$obytes2 - $obytes1}]
set xius [expr {$ioqs * 2}]
set xous [expr {$ooqs * 2}]

# Determine biggest unit and use
proc biggestUnit {nhumnum} {
 global sibin
 if {$sibin == 1} {set thousand 1000; set ibi i} {set thousand 1024 ; set ibi ""}
 if {($nhumnum / $thousand) == 0} {
  set num $nhumnum
  # less than a ki(lo|bi)byte
  return [format "%sB/s" $num]
 }
 if {($nhumnum / ($thousand * $thousand)) == 0} {
  set num [expr {$nhumnum / ($thousand)}]
  # less than a me(ga|bi)byte
  return [format "%sk%sB/s" $num $ibi]
 }
 if {($nhumnum / ($thousand * $thousand * $thousand)) == 0} {
  set num [expr {$nhumnum / ($thousand * $thousand)}]
  # less than a gi(ga|bi)byte
  return [format "%sM%sB/s" $num $ibi]
 }
 if {($nhumnum / ($thousand * $thousand * $thousand * $thousand)) == 0} {
  set num [expr {$nhumnum / ($thousand * $thousand * $thousand)}]
  # less than a te(ra|bi)byte
  return [format "%sG%sB/s" $num $ibi]
 }
 if {($nhumnum / ($thousand * $thousand * $thousand * $thousand * $thousand)) == 0} {
  set num [expr {$nhumnum / ($thousand * $thousand * $thousand  * $thousand)}]
  # less than a pe(ta|bi)byte
  return [format "%sT%sB/s" $num $ibi]
 }
 if {($nhumnum / ($thousand * $thousand * $thousand * $thousand * $thousand * $thousand)) == 0} {
  set num [expr {$nhumnum / ($thousand * $thousand * $thousand  * $thousand * $thousand)}]
  # less than an ex(a|bi)byte ... HOLY FUCK
  # How does this happen?!
  return [format "%sP%sB/s" $num $ibi]
 }
 if {($nhumnum / ($thousand * $thousand * $thousand * $thousand * $thousand * $thousand * $thousand)) == 0} {
  set num [expr {$nhumnum / ($thousand * $thousand * $thousand  * $thousand * $thousand)}]
  # less than a megaex(a|bi)byte ... HOLY FUCK
  # How does this happen?!
  return [format "%sE%sB/s" $num $ibi]
 }
 if {($nhumnum / ($thousand * $thousand * $thousand * $thousand * $thousand * $thousand * $thousand * $thousand)) == 0} {
  set num [expr {$nhumnum / ($thousand * $thousand * $thousand  * $thousand * $thousand * $thousand)}]
  # less than a megaex(a|bi)byte ... HOLY FUCK
  # How does this happen?!
  return [format "%sME%sB/s" $num $ibi]
 } {
  set num [expr {$nhumnum / ($thousand * $thousand * $thousand  * $thousand * $thousand * $thousand  * $thousand)}]
  # more than a gigex(a|bi)byte ... HOLY FUCK
  # How does this happen?!
  return [format "%sGE%sB/s" $num $ibi]
 }
}

if {$mode == "tmux"} {
	puts stdout [format "i:%s o:%s" [biggestUnit $xius] [biggestUnit $xous]]
} {
	puts stdout [format "Over one half of one second, %s bytes have come in, and %s bytes have gone out - approximately %sB/s and %sB/s, respectively. Ja mata!" $ioqs $ooqs $xius $xous]
}
