#!/bin/bash
#set -e

mask="built-in\.a$"

echo ">>> Analyzing object file sizes "
ls -al vmlinux*
find . | grep -E $mask

declare -A seen_objs  # 关联数组用来避免重复 obj
total_size=0
libs=$(find . | grep -E $mask | tr ' ' '\n' | uniq; echo "vmlinux.a")

for lib in $libs; do
    if [ ! -f "$lib" ]; then
        continue
    fi

    while read obj; do
        if [[ "$obj" == ./* ]]; then
            obj=${obj#./}  # 删除开头的 ./
        fi    
 
        # 判断是否已经处理过该对象文件
        if [[ -n "${seen_objs[$obj]}" ]]; then
            continue
        fi

        if [ -f "$obj" ]; then
            size=$(stat -c%s "$obj")
            total_size=$((total_size + size))
            echo "==> Processing $lib $obj $size total:$total_size" 

            seen_objs["$obj"]=$size
        fi

    done < <(ar t "$lib")  # 关键：将 ar 输出作为 while 的输入，避免子 shell    
done


# 按大小倒序输出
rm max_obj.txt || true

echo "${#seen_objs[@]} 按文件大小倒序排序 前 512:" >> max_obj.txt

top_size=0
for obj in "${!seen_objs[@]}"; do
    echo "${seen_objs[$obj]} $obj"
done | sort -rn | head -n 512 | awk '
    {
        printf "==> %s %s\n", $2, $1;
        top_size += $1;  # 累加文件大小
    }
    END {
        print "Total size of top 512 objects:", top_size;
    }
' >> max_obj.txt
cat max_obj.txt