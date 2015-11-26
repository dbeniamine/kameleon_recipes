#RECIPE=$(wildcard *.yaml)
RECIPE=debian8_virt_dev.yaml
MEM=-m 4G
CPU=-smp cpus=4
#SSH=-redir tcp:2022::22 -display none
GRAB=""-alt-grab
VGA="" #-vga std
DEBUG=-s
DEPS=$(shell  find . -name "*.yaml" | grep -v build)
IMG_FILE=$(RECIPE:.yaml=.qcow2)
IMG=build/$(RECIPE:.yaml=)/$(IMG_FILE)
VIRT_ROOT=$(PWD)/mnt
VIRT_HOME=$(VIRT_ROOT)/home/david

all: start

$(IMG): $(DEPS)
	kameleon build $(RECIPE) #--checkpoint --cache
	cp $(IMG) $(IMG).bak

# Start the kvm
start: $(IMG)
	kvm $(GRAB) -hda $(IMG) $(MEM)  $(CPU) $(SSH) $(DEBUG) &

startonly:
	touch $(IMG)
	make start

restore:
	cp -v $(IMG).bak $(IMG)

.PHONY: clean mount loadmodule unloadmodule umount umountpre premount, mountencfs

clean:
	rm -rf build/*

# Mount the disk image
#mount : premount mountencfs
mount : premount

mountencfs:
	encfs $(VIRT_HOME)/.Documents $(VIRT_HOME)/Work

premount: loadmodule
	sudo qemu-nbd --connect /dev/nbd0  $(IMG)
	sudo mkdir -p ./mnt
	if test -e /dev/nbd0p1; then sudo mount /dev/nbd0p1 ./mnt; fi

# Load nbd module to allow mounting disk image
loadmodule:
	if test -z "$(lsmod | grep nbd)"; then \
		sudo modprobe nbd max_part=8;\
		fi

# Unload the nbd module
unloadmodule:
	sudo rmmod nbd


umountpre:
	if test ! -z "`\ls $(VIRT_ROOT)`"; \
		then if [ ! -z "`cat /etc/mtab | grep \"$(VIRT_HOME)/Documents\"`" ]; \
		then fusermount -u $(VIRT_HOME)/Documents; fi; \
		sudo umount ./mnt; fi
	if [ -e /dev/nbd0 ]; then sudo qemu-nbd -d /dev/nbd0; fi

# Virtual target to umount disk and remove module
umount: umountpre unloadmodule
