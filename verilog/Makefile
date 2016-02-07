
# VIVADO Simulation Parameters
#VLOG=xvlog
#VFLAGS= --work work
#SVFLAGS= --sv --work work

# MODELSIM Simulation Parameters
VLOG=vlog
VFLAGS= -work work
SVFLAGS= -sv -work work

#Source directory
SRCDIR   = ./src
BUILDDIR = ./build
INCDIR   = ./include

#---------------------------------------------------------------------------------
#DO NOT EDIT BELOW THIS LINE
#---------------------------------------------------------------------------------

VSRCS=$(shell find $(SRCDIR) -type f -name "*.v")
SVSRCS=$(shell find $(SRCDIR) -type f -name "*.sv")
VOBJS=$(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(VSRCS:.v=.ov))
SVOBJS=$(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(SVSRCS:.sv=.osv))

.PHONY: all sim clean

all: sim

sim: $(VOBJS) $(SVOBJS)

$(BUILDDIR)/%.ov: $(SRCDIR)/%.v
	@mkdir -p $(dir $@)
	$(VLOG) $(VFLAGS) $< && touch $@

$(BUILDDIR)/%.osv: $(SRCDIR)/%.sv
	@mkdir -p $(dir $@)
	$(VLOG) $(SVFLAGS) $< && touch $@

clean:
	$(RM) -rf $(BUILDDIR)

destroy: clean
	$(RM) -rf xsim.dir
	$(RM) -rf work
	$(RM) xvlog.log
	$(RM) xvlog.pb
