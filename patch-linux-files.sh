#!/bin/bash

[ -e ./scripts/package/builddeb ] && sed -i '/System.map/s/^/#/' ./scripts/package/builddeb

[ -e ./kernel/trace/power-traces.c ] && echo "" > ./kernel/trace/power-traces.c
[ -e ./include/trace/events/power.h ] && cat > ./include/trace/events/power.h << HDR_EOF

#define trace_suspend_resume(x,...)
#define trace_cpu_idle(x,...)
#define trace_cpu_idle_miss(x,...)

#define trace_pm_qos_add_request(x)
#define trace_pm_qos_update_request(x)
#define trace_pm_qos_remove_request(x)
#define trace_pm_qos_update_flags(x,...)
#define trace_pm_qos_update_target(x,...)

#define trace_dev_pm_qos_add_request(x,...)
#define trace_dev_pm_qos_update_request(x,...)
#define trace_dev_pm_qos_remove_request(x,...)

#define trace_device_pm_callback_start(x,...)
#define trace_device_pm_callback_end(x,...)
#define trace_wakeup_source_activate(x,...)
#define trace_wakeup_source_deactivate(x,...)

#define trace_cpu_frequency(x,...)
#define trace_cpu_frequency_enabled() false
#define trace_cpu_frequency_limits(x,...)

#define trace_guest_halt_poll_ns(x,...)
#define trace_guest_halt_poll_ns_grow(x,...)
#define trace_guest_halt_poll_ns_shrink(x,...)

#define trace_pstate_sample_enabled() false
#define trace_pstate_sample(x,...)

HDR_EOF

[ -e ./fs/xfs/xfs_trace.h ] && echo "" > ./fs/xfs/xfs_trace.h
#[ -e ./drivers/net/hyperv/netvsc_trace.h ] && echo "" > ./drivers/net/hyperv/netvsc_trace.h

if [ -e ./drivers/hv/Makefile ]; then
  sed -i 's/hv_trace.o//g'      ./drivers/hv/Makefile
  sed -i '/hv_debugfs.o/s/^/#/' ./drivers/hv/Makefile
  
  c_src=$(find ./drivers/hv/ | grep ".c$" | tr ' ' '\n' | uniq;)

  for src in $c_src; do
    if [ ! -f "$src" ]; then
        continue
    fi

	sed -i -E '
	/^[[:space:]]*trace_vmbus_.*\);/ {
		s/^/{}\/\//
		b
	}
	/^[[:space:]]*hv_debug_.*\);/ {
		s/^/{}\/\//
		b
	}
	/^[[:space:]]*trace_vmbus_/ {
		s/^/{}\/\//
		:a
		n
		s/^/\/\/\//
		/\);/! ba
	}
	' "$src"

  done
fi

#[  -e ./drivers/hid/Makefile ] && sed -i '/debug.o/s/^/#/' ./drivers/hid/Makefile

if [ -e ./drivers/hid/Makefile ]; then
  sed -i '/debug.o/s/^/#/'      ./drivers/hid/Makefile
  sed -i '/hid-wiimote/s/^/#/'      ./drivers/hid/Makefile
  
  c_src=$(find ./drivers/hid/ | grep ".c$" | tr ' ' '\n' | uniq;)

  for src in $c_src; do
    if [ ! -f "$src" ]; then
        continue
    fi

    sed -i -e '/^[[:space:]]*hid_debug_.*);/ s/^/{}\/\//; t' -e '/^[[:space:]]*hid_debug_/,/);/ s/^/{}\/\//' "$src"
    sed -i -e '/^[[:space:]]*hid_dump_.*);/ s/^/{}\/\//; t' -e '/^[[:space:]]*hid_dump_/,/);/ s/^/{}\/\//' "$src"

  done
fi


#[  -e ./fs/smb/client/Makefile ] && sed -i 's/trace.o//g' ./fs/smb/client/Makefile #会link出错

if [ -e ./fs/smb/client/Makefile ]; then
  sed -i 's/trace.o//g'      ./fs/smb/client/Makefile
  
  c_src=$(find ./fs/smb/client/ | grep ".c$" | tr ' ' '\n' | uniq)

  for src in $c_src; do
    if [ ! -f "$src" ]; then
        continue
    fi

	sed -i -E '
	/^[[:space:]]*trace_smb3_.*\);/ {
		s/^/{}\/\//
		b
	}
	/^[[:space:]]*trace_smb3_/ {
		s/^/{}\/\//
		:a
		n
		s/^/\/\/\//
		/\);/! ba
	}
	' "$src"


	sed -i -E '
	/^[[:space:]]*trace_cifs_.*\);/ {
		s/^/{}\/\//
		b
	}
	/^[[:space:]]*trace_cifs_/ {
		s/^/{}\/\//
		:a
		n
		s/^/\/\/\//
		/\);/! ba
	}
	' "$src"

  done
fi

if [ -e ./fs/smb/client/cifsproto.h ]; then

    sed -i -E '
    /^[[:space:]]*trace_smb3_.*\);$/ {
        c\{}\\
        b
    }
    /^[[:space:]]*trace_smb3_/ {
        c\{}\\
        :a
        n
        c\ \\
        /\);$/! ba
    }
    ' ./fs/smb/client/cifsproto.h 
fi

#[  -e ./fs/xfs/Makefile ] && sed -i '/xfs_trace.o/s/^/#/' ./fs/xfs/Makefile

if [ -e ./fs/xfs/Makefile ]; then
  sed -i '/xfs_trace.o/s/^/#/'      ./fs/xfs/Makefile
  
  c_src=$(find ./fs/xfs/ | grep ".c$" | tr ' ' '\n' | uniq;)

  for src in $c_src; do
    if [ ! -f "$src" ]; then
        continue
    fi


	sed -i -E '
	/^[[:space:]]*trace_xfs_.*\);/ {
		s/^/{}\/\//
		b
	}
	/^[[:space:]]*trace_xfs_/ {
		s/^/{}\/\//
		:a
		n
		s/^/\/\/\//
		/\);/! ba
	}
	' "$src"

	sed -i -E '
	/^[[:space:]]*trace_xlog_.*\);/ {
		s/^/{}\/\//
		b
	}
	/^[[:space:]]*trace_xlog_/ {
		s/^/{}\/\//
		:a
		n
		s/^/\/\/\//
		/\);/! ba
	}
	' "$src"

  done
fi

#[  -e ./drivers/net/hyperv/Makefile ] && sed -i 's/netvsc_trace.o//g'      ./drivers/net/hyperv/Makefile

if [ -e ./drivers/net/hyperv/Makefile ]; then
  sed -i 's/netvsc_trace.o//g'      ./drivers/net/hyperv/Makefile
  
  c_src=$(find ./drivers/net/hyperv/ | grep ".c$" | tr ' ' '\n' | uniq;)

  for src in $c_src; do
    if [ ! -f "$src" ]; then
        continue
    fi

	sed -i -E '
	/^[[:space:]]*trace_nvsp_.*\);/ {
		s/^/{}\/\//
		b
	}
	/^[[:space:]]*trace_rndis_.*\);/ {
		s/^/{}\/\//
		b
	}    
	/^[[:space:]]*trace_nvsp_/ {
		s/^/{}\/\//
		:a
		n
		s/^/\/\/\//
		/\);/! ba
	}
	' "$src"

  done
fi
