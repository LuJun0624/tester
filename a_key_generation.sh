#!/bin/bash
#author by :Sundy.wang
#describe:A key produting version.

export PATH=.:$PATH
export OUT_HOST_ROOT=.
#date=$(date +%t)
#echo "=====Build time:"$(date)"===="
start='date'
echo "argume:$@"
echo "scname:$0"
ap_pwd=$(pwd)
echo "=====111111path<"$(pwd)">==="${HOME}"==="
my_code_path=${HOME}"/SEND_VERSION"
cd $my_code_path
cd ..
my_path=$(pwd)
echo "=====222path<"$(pwd)">========"
cd $ap_pwd
echo $my_code_path
echo $my_path
echo $ap_pwd
echo "=============>>PATH<<"$(pwd)">>========"

if [ "$3" = "" ]
	then
    echo -e "\033[31;1m Please Enter 3 parameter !!.\033[0m"
    exit
fi

cp -r $my_code_path/$1/mba.mbn $(pwd)/quectel_build/packaged_file/modem/.
if [[ $? -eq 0 ]];
then 
   echo "copy scuessful" 
else 
   echo "copy fail"
   exit -1 ;
fi

cp -r $my_code_path/$1/qdsp6sw.mbn $(pwd)/quectel_build/packaged_file/modem/.
if [[ $? -eq 0 ]];
then 
    echo "copy scuessful"
else
    echo "copy fail"
    exit -1;
fi

cp -r $my_code_path/$1/orig_MODEM_PROC_IMG_9607.*.prodQ.elf  $(pwd)/quectel_build/packaged_file/modem/.
if [[ $? -eq 0 ]];
then 
    echo "copy scuessful"
else
    echo "copy fail"
    exit -1;
fi

cp -r $my_code_path/$1/orig_MODEM_PROC_IMG_9607.*.prodQ.elf.map  $(pwd)/quectel_build/packaged_file/modem/.
if [[ $? -eq 0 ]];
then 
    echo "copy scuessful"
else
    echo "copy fail"
    exit -1;
fi


#要先将编译出来的modem的bin文件 mba.mbn ，qdsp6sw.mbn copy到 quectel_build/packaged_file/modem/再去执行下面的脚本
cd  $ap_pwd/quectel_build
./quectel_do.sh do $1
if [ $? -ne 0 ]; then
	echo "quectel_do.sh run failed, Please check !!!!!!!!!!!!!"
	exit 1
fi

cd  $ap_pwd/common/build
echo "============="$(pwd)"============"
rm -rf ./NON-HLOS.ubi
rm -rf ./targetfiles.zip
./ModemUBI\&\&Updatafiles_gen.sh
chmod -R 777 ../../apps_proc/poky/build/tmp-glibc/deploy/images/mdm9607-perf/*

echo "=========pwd:"$(pwd)
if [ -d $my_path/$2 ]; 
then
    echo "$2 exit!"
else
    echo "=========The folder no exit!======="
    mkdir -p $my_path/$2
    mkdir -p $my_path/$2/upgrade
    mkdir -p $my_path/$2/dbg
    mkdir -p $my_path/$2/update
    mkdir -p $my_path/$2/update/firehose
fi

echo "=========build end ==> copy upgrade begin for fota files============="
cp ./targetfiles.zip $my_path/$2/upgrade/.

echo "========= copy update begin============="

if [ ! -e  ../../apps_proc/poky/build/tmp-glibc/deploy/images/mdm9607-perf/mdm9607-ota-target-image-ubi/SYSTEM/firmware/image/mba.mbn ] ;then
    cp NON-HLOS.ubi   $my_path/$2/update/.
fi
if [ -e  ../../apps_proc/poky/build/tmp-glibc/deploy/images/mdm9607-perf/mdm9607-ota-target-image-ubi/SYSTEM/firmware/image/mba.mbn ] ;then
    mkdir -p $my_path/${2}_Secboot
    mkdir -p $my_path/${2}_Secboot/update
    mkdir -p $my_path/${2}_Secboot/secboot
    cp NON-HLOS.ubi   $my_path/${2}_Secboot/update/.
     cp $ap_pwd/apps_proc/poky/build/tmp-glibc/deploy/images/mdm9607-perf/ql-rootfs.tar.gz $my_path/${2}_Secboot/secboot
fi


cd  $ap_pwd/quectel_build
#copy sbl,tz 
grep -wq ">data.ubi<" ../common/config/partition_nand.xml && cp ./packaged_file/data/data.ubi $my_path/$2/update/ || echo "the project don't need data.ubi\n"
cp ./packaged_file/sbl/ENPRG9x07.mbn ./packaged_file/sbl/NPRG9x07.mbn ./packaged_file/sbl/sbl1.mbn ./packaged_file/tz/tz.mbn ./packaged_file/usrdata/usrdata.ubi $my_path/$2/update/.
#copy rpm
if [[ $1 = 'EG91_JP' ]];
then 
    echo "$1 exit! copy rmp"
	cp ./packaged_file/rpm/$1/rpm.mbn $my_path/$2/update/.
elif [[ $1 = 'EG95_JP' ]];
then
    cp ./packaged_file/rpm/$1/rpm.mbn $my_path/$2/update/.
else
    echo "=======copy default RMP.mbn ! ====="
    cp ./packaged_file/rpm/rpm.mbn $my_path/$2/update/.
fi
cp ./packaged_file/contents.xml $my_path/$2/.

#copy the firehose relate
rm -rf $my_path/$2/update/firehose/*
cp -rf ./packaged_file/firehose/*  $my_path/$2/update/firehose
rm -rf $my_path/$2/update/firehose/*_factory.xml
#去掉firehose 配置脚本里，擦除，烧录 cefs.mbn 这两行，因这是升级版本
#sed -i '/erase/{$!N;/cefs\.mbn/{d}}'  $my_path/$2/update/firehose/rawprogram_nand_*
#cd $my_path/$2/update/firehose/
#filename=rawprogram_nand_*
#mv $(basename $filename) $(basename $filename .xml)_update.xml

# copy partition files form apps_proc, the partition different for different project
cd  $ap_pwd
echo "=== 1  copy partition files form apps_proc==="
cp ./common/build/partition.mbn  $my_path/$2/update/.
cp ./common/config/partition_nand.xml  $my_path/$2/update/.
# 去掉 partition_nand.xml 里下载cefs.mbn 那行，因为这是update版本
sed -i '/cefs\.mbn/{d}' $my_path/$2/update/partition_nand.xml

# copy linux bin
echo “======copy  linux bin to update firmware package  begin======”
cd $ap_pwd/apps_proc/poky/build/tmp-glibc/deploy/images/mdm9607-perf
cp mdm9607-recovery.ubi mdm9607-sysfs.ubi  mdm9607-boot.img appsboot.mbn $my_path/$2/update/.

echo "========= copy dbg begin============="
cd  $ap_pwd
cp -rf ./quectel_build/packaged_file/modem/*.elf  $my_path/$2/dbg/.
cp -rf ./quectel_build/packaged_file/modem/*.elf.map  $my_path/$2/dbg/.
cp -rf ./quectel_build/packaged_file/sbl/*.elf  $my_path/$2/dbg/.
cp -rf ./quectel_build/packaged_file/rpm/*.elf  $my_path/$2/dbg/.
cp -rf ./quectel_build/packaged_file/tz/*.elf  $my_path/$2/dbg/.
cp $ap_pwd/apps_proc/poky/build/tmp-glibc/sysroots/mdm9607-perf/boot/vmlinux $my_path/$2/dbg/.

echo "=========zip begin============="
cd $my_path/$2




echo "==========<FACTORY_VER>==================="
cd $ap_pwd/common/build

echo "===========[factory]path"$(pwd)"==========="
if [ -d $my_path/$3 ];
then 
    echo "$2 exit!"
else
    echo "=======The folder no exit!====="
    mkdir -p $my_path/$3
    mkdir -p $my_path/$3/update
    mkdir -p $my_path/$3/update/firehose
fi

echo ""
echo ""
echo "======= copy factory update begin====="
if [ ! -e  ../../apps_proc/poky/build/tmp-glibc/deploy/images/mdm9607-perf/mdm9607-ota-target-image-ubi/SYSTEM/firmware/image/mba.mbn ] ;then
	cp NON-HLOS.ubi   $my_path/$3/update/.
fi



cd  $ap_pwd/quectel_build

grep -wq ">data.ubi<" ../common/config/partition_nand.xml && cp ./packaged_file/data/data.ubi $my_path/$3/update/ || echo "the project don't need data.ubi\n"
#copy sbl,tz 
cp ./packaged_file/sbl/ENPRG9x07.mbn ./packaged_file/sbl/NPRG9x07.mbn ./packaged_file/sbl/sbl1.mbn ./packaged_file/tz/tz.mbn ./packaged_file/usrdata/usrdata.ubi $my_path/$3/update/.
#copy rpm
if [[ $1 = 'EG91_JP' ]];
then 
    echo "$1 exit! copy rmp"
	cp ./packaged_file/rpm/$1/rpm.mbn $my_path/$3/update/.
elif [[ $1 = 'EG95_JP' ]];
then
    cp ./packaged_file/rpm/$1/rpm.mbn $my_path/$3/update/.
else
    echo "=======copy default RMP.mbn ! ====="
    cp ./packaged_file/rpm/rpm.mbn $my_path/$3/update/.
fi
cp ./packaged_file/contents.xml $my_path/$3/.

#copy the firehose relate
rm -rf $my_path/$3/update/firehose/*
cp -rf ./packaged_file/firehose/*  $my_path/$3/update/firehose
rm -rf $my_path/$3/update/firehose/*_update.xml

#cd $my_path/$3/update/firehose/
#filename=rawprogram_nand_*
#mv $(basename $filename) $(basename $filename .xml)_factory.xml

# copy partition files form apps_proc, the partition different for different project
cd  $ap_pwd
echo "=== 1  copy partition files form apps_proc==="
cp ./common/build/partition.mbn  $my_path/$3/update/.
cp ./common/config/partition_nand.xml  $my_path/$3/update/.

#copy cefs.mbn, factory.xqcn
cp ./QCN/$1/cefs.mbn  $my_path/$3/update/.
if [ "$1" = "EG95EX" ] || [ "$1" = "EC25EUX" ] || [ "$1" = "EG91EX" ] || [ "$1" = "EC21EUX" ] || [ "$1" = "EC25E_EMBMS" ] || [ "$1" = "EC25E" ] || [ "$1" = "EC25EU" ] || [ "$1" = "EC25EX_GC" ] || [ "$1" = "EC21AUX_GA" ] || [ "$1" = "EG91AUX" ] || [ "$1" = "EC25EM" ]
then
	cp ./QCN/$1/cefs.mbn  ./quectel_build/.
	cd ./quectel_build/
	./modify_cefs_factory_magic cefs.mbn cefs.mbn.bak 0x35866888 0x92347759
	cd -
	mv ./quectel_build/cefs.mbn.bak $my_path/$3/update/cefs.mbn
fi
cp ./QCN/$1/factory.xqcn  $my_path/$3/update/.

# copy linux bin
echo “======copy  linux bin to update firmware package  begin======”
cd $ap_pwd/apps_proc/poky/build/tmp-glibc/deploy/images/mdm9607-perf
cp mdm9607-recovery.ubi mdm9607-sysfs.ubi  mdm9607-boot.img appsboot.mbn $my_path/$3/update/.

# Eve add mdm9607-perf-factory-sysfs.ubi copy path
if [ -f "mdm9607-perf-factory-sysfs.ubi" ]
then
	cp mdm9607-perf-factory-sysfs.ubi $my_path/$3/update/mdm9607-sysfs.ubi
else
	cp mdm9607-sysfs.ubi $my_path/$3/update/mdm9607-sysfs.ubi
fi

# asa.wang-2018/06/01, copy project relate file start
# wayne.wei-2019/10/12, copy EC20CE_FASG project relate file start
cd  $ap_pwd/quectel_build
if [ "$1" = "EC25EU" ] || [ "$1" = "EC20CE_FASG" ] || [ "$1" = "EC20CE_FASG_OCL" ]
	then
	#copy sbl elf and mbn file
	echo -e "\033[31;1m copy $1 related sbl file !!.\033[0m"	
	cp -rf ./packaged_file/sbl/$1/*.elf  $my_path/$2/dbg/.
	cp ./packaged_file/sbl/$1/ENPRG9x07.mbn ./packaged_file/sbl/$1/NPRG9x07.mbn ./packaged_file/sbl/$1/sbl1.mbn $my_path/$2/update/.
	cp ./packaged_file/sbl/$1/ENPRG9x07.mbn ./packaged_file/sbl/$1/NPRG9x07.mbn ./packaged_file/sbl/$1/sbl1.mbn $my_path/$3/update/.
fi
# asa.wang-2018/06/01, end
#charles add for fasg hw
if [ "$1" = "EC20CE_FASG_HW" ]
then
	#copy sbl elf and mbn file
	echo -e "\033[31;1m copy $1 related sbl file !!.\033[0m"	
	cp -rf ./packaged_file/sbl/$1/*.elf  $my_path/$2/dbg/.
	cp ./packaged_file/sbl/$1/ENPRG9x07.mbn ./packaged_file/sbl/$1/NPRG9x07.mbn ./packaged_file/sbl/$1/sbl1.mbn $my_path/$2/update/.
	cp ./packaged_file/sbl/$1/ENPRG9x07.mbn ./packaged_file/sbl/$1/NPRG9x07.mbn ./packaged_file/sbl/$1/sbl1.mbn $my_path/$3/update/.
	#copy oemapp for softsim
	OEMAPP=$ap_pwd/quectel_build/project_configfiles/quectel_process/customer/HW/oemapp.ubi 
else
	OEMAPP=$ap_pwd/quectel_build/project_configfiles/quectel_process/other/ss/oemapp.ubi 
fi
if [ ! -f $OEMAPP ]
then
	echo "************OEMAPP don't exist************"
	exit -1
else
	echo "copy oemapp img"
	cp $OEMAPP $my_path/$2/update
	cp $OEMAPP $my_path/$3/update
fi

echo "======zip begin======"
cd $my_path/$3

echo "=====Del tmp folder ($1)and($2)======"
cd $my_path

tool_table=(tree md5sum unix2dos dos2unix)
for i in "${!tool_table[@]}"
do
    which ${tool_table[$i]}
    if [ "$?" != "0" ]
    then
         apt-get install -y ${tool_table[$i]}
        if [ "$?" != "0" ]
        then
            echo "Error: no such [ ${tool_table[$i]} ] tool"
            exit -1
        else
            echo "Install [ ${tool_table[$i]} ] sucess"
        fi
    fi
done

MD5_path1=$my_path/$2/
MD5_path2=$my_path/$3/

echo "$MD5_path1, $MD5_path2"
typeset -u TO_UPPER
if [ -d "$MD5_path1" ] && [ -d "$MD5_path2" ]
then
	for (( m=1; $m<=2; m++ ))
	do
		md5_path=`eval echo '$MD5_path'"$m"`
		cd $md5_path
        chmod +444 -R ./
		echo "PATH: $md5_path"
    	echo -e "\033[32m\tmd5 path:\033[0m\n\t[ $(pwd) ]"
		rm md5.txt
		echo -e "VERSION:1.0\nFILE:START" > md5.txt
    	n=`tree -if --noreport | sed '/\.\/dbg/d' | wc -l`
    	for (( i=1; $i<=$n;i++ ))
    	do
    	    md5_file=`tree -if --noreport | sed '/\.\/dbg/d' |sed -n "$i""p"`
    	    if [ -d "$md5_file" ] || [ "$md5_file" = "./md5.txt" ]
    	    then
    	        continue
    	    fi
			echo "md5 file [ $md5_file ]"
    	    md5_info=`md5sum $md5_file`
            if [[ $? -eq 1 ]]
            then
                echo -e "\033[31mError:\033[0m file [ $md5_file ]"
                exit 1
            fi
    	    TO_UPPER=`echo $md5_info | awk '{printf $1}'`
    	    file_md5=`echo $md5_info | awk '{printf $2}' | sed 's/\//\\\\/g'`
    	    echo "FILE:${file_md5:1}:$TO_UPPER" >> md5.txt
    	done
    	echo "FILE:END" >> md5.txt
		unix2dos md5.txt
    	cd - > /dev/null
	done
else
	echo "No such path $1 or $2"
	exit 1
fi

#echo "=====Build time:"$(date)"===="
minu_time=$(($SECONDS/60))
sec_time=$(($SECONDS%60))

echo "===============Build_time:"$minu_time"m"$sec_time"s==============="

echo "===============Build version==============="
cat $ap_pwd/apps_proc/poky/build/tmp-glibc/work/mdm9607-oe-linux-gnueabi/machine-image/1.0-r0/rootfs/etc/quectel-project-version

