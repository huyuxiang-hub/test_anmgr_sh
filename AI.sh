#!/bin/bash
下周如厕出去
num_of_para=8
opt[1]="anamgr-edm"
opt[2]="anamgr-deposit-tt"
opt[3]="anamgr-normal"
opt[4]="anamgr-genevt"
opt[5]="anamgr-deposit"
opt[6]="anamgr-interesting-process"
opt[7]="anamgr-optical-parameter"
opt[8]="anamgr-timer"


function generate_anamgr(){
    local index=$1
    local num=$2
    
    for(( i=1 ; i <= $num ; i++))
    do
       if [ $i -eq $index ]
       then
          echo -n "--"${opt[$i]}" "
       else
          echo -n "--no-"${opt[$i]}" "
       fi
    done
}

for(( i=1 ; i <= $num_of_para; i++))
do
   list_opt[$i]=$( generate_anamgr $i $num_of_para )
done

IFS_OLD=$IFS
IFS=$':'


function template_det(){
 #    local RUN=$1
     local EVTMAX=$1
     local OUT=$2
     local LIST=$3
     local OPT=$4
 #   echo ${OPT}
    shift $#
    cat > $OUT <<EOF
#!/bin/bash
 
#source /cvmfs/juno.ihep.ac.cn/sl6_amd64_gcc830/Pre-Release/J20v1r0-Pre2/setup.sh
source /cvmfs/juno.ihep.ac.cn/centos7_amd64_gcc830/Pre-Release/J20v2r0-Pre0/setup.sh
flag=0


/junofs/users/huyuxiang/jobmom.sh \$\$ >& detsim_${LIST}/log-detsim-1.txt.mem.usage &
(time python /cvmfs/juno.ihep.ac.cn/centos7_amd64_gcc830/Pre-Release/J20v2r0-Pre0/offline/Examples/Tutorial/share/tut_detsim.py --evtmax ${EVTMAX} --seed 1122  --output detsim_${LIST}/detsim-1.root --user-output detsim_${LIST}/user-detsim-1.root  ${OPT}  gun --particles neutron --volume pTarget --material LS  ) >& detsim_${LIST}/log-detsim-1.txt && flag=1
if [ \${flag} -eq 1 ]
then 
  cd detsim_${LIST}/
  root -l -b -q drawmem.C+
fi
EOF
}


EVTMAX=1000

for (( k=1 ; k<=$num_of_para ; k++ ))

do
   echo $k
   if [ -d detsim_${opt[$k]} ]
   then
      echo "detsim_${opt[$k]} exsist...."
   else
       mkdir detsim_${opt[$k]}
   fi
   
   if [ $k -ne 1 ]
   then
     touch detsim_${opt[$k]}/detsim-1.root
   fi
   
   cp /workfs/juno/huyuxiang/drawmem.C detsim_${opt[$k]}/
   # for ((i=${START}; i<$[$START+$N]; i++))
   #  do
   #    echo $i
      # echo ${cmd_opt[$k]}
       out="run-detsim-${opt[$k]}.sh"
       template_det  ${EVTMAX} ${out} ${opt[$k]} ${list_opt[$k]}
       chmod +x ${out}
       hep_sub run-detsim-${opt[$k]}.sh -mem 8000 -wn bws0768.ihep.ac.cn

done

IFS=${IFS_OLD}



:<<BlOCK

for (( k=1 ; k<=$num_of_para ; k++ ))
do
   cd ./detsim_${opt[$k]}/
   while (( 1 ))
     do
        grep "SNiPER::Context Terminated Successfully" log-detsim-1.txt 
        if [ $? -eq 0 ]
        then 
           root -l -b -q drawmem.C+
           break
        fi
     done
   cd ../
done

BlOCK


#echo ${list_opt[2]}



#generate_anamgr 1 $num_of_para


#name[1]="anamgr nh"
#echo -n  ${name[1]} " "
#echo "hello" 
