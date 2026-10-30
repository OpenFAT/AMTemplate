# Creates the block's empty cell, its outline and ports, saved as .mag and .lef
# (`make init_layout` then runs mag2gds for the .gds).
# `make init_layout` sets TOP, DEF_TEMPLATE, DIE_AREA and PINS from config.mk first.
if {$DEF_TEMPLATE ne ""} {
    # The DEF carries the die area and pin positions; its DESIGN becomes the cell.
    set fh [open $DEF_TEMPLATE]
    regexp {DESIGN\s+(\S+)} [read $fh] -> design
    close $fh
    def read $DEF_TEMPLATE
    if {$design ne $TOP} { cellname rename $design $TOP }
    load $TOP
} else {
    load $TOP
    lassign $DIE_AREA x0 y0 x1 y1
    # In um: magic rescales its grid when the pins are painted, and raw values would not follow.
    property FIXED_BBOX "${x0}um ${y0}um ${x1}um ${y1}um"
    # One 1um met4 port per pin along the bottom edge; move them where they belong.
    set x [expr {$x0 + 1}]
    foreach pin $PINS {
        box ${x}um ${y0}um [expr {$x + 1}]um [expr {$y0 + 1}]um
        paint met4
        label $pin FreeSans 0.25u -met4
        port make
        port class bidirectional
        set x [expr {$x + 3}]
    }
}

save ${TOP}.mag
lef write ${TOP}.lef -hide -pinonly
