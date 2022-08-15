#!/bin/bash
echo "running $0 ..."
echo -e "\$1:$1\n\$2:$2"
echo "自动递增pod版本..."

# 1. 执行pod验证操作 pod lib lint --allow-warnings 。
# 2. 验证执行成功后，递增版本号。
# 3. 打tag 并推送到远程仓库。git tag 'a.b.c';git push --tag
# 4. pod repo push Specs仓库名 xxx.podspec


targetDir="$1"
if [[ -z "$targetDir" ]]; then
	targetDir=./
fi
echo "目标地址:$targetDir"
cd "$targetDir"
# exit


targetSpecsName=ttc_mirror_repo

# if [[ -z "$targetSpecsName" ]]; then
# 	echo "没有指定Specs Name，默认为:MySpec"
# 	targetSpecsName=MySpec
# else
# 	echo "指定了Specs Name:$targetSpecsName"
# fi


getopts(){
	while getopts a:b:c: opt 
	do 	
		case ${opt} in
			a) echo "参数a的值：$OPTARG";;
			b) echo "参数b的值：$OPTARG";;
			c) echo "参数c的值：$OPTARG";;
			# echo "未定义参数:$opt, value:$OPTARG";;
		esac
		#statements
	done
}



pod_lib_lint(){
	echo -e "\n验证pod:pod lib lint --allow-warnings..."
	pod lib lint --allow-warnings --use-libraries  --sources='git@gitlab.xxxx.com:podhub/myspec.git'
	if [[ $? -eq 0 ]]; then
		echo "pod 验证成功!"
	else
		echo "pod 验证失败!!"
		exit 1
	fi	
}


_increment_version ()
{
  declare -a part=( ${1//\./ } )
  declare    new
  declare -i carry=1
  CNTR=${#part[@]}-1
  len=${#part[CNTR]}
  new=$((part[CNTR]+carry))
  part[CNTR]=${new}
  new="${part[*]}"
  echo -e "${new// /.}"
}
#version='1.2.3.9'
#
#increment_version $version
#exit



increase_version () {
	podspecFile=$(ls *.podspec)
	echo "podspecFile:$podspecFile"

	echo -e "\n即将递增版本号..."
	version_line_str=$(cat *.podspec|grep "s.version ")
	current_version=${version_line_str#*= }
	current_version=$(echo ${current_version//\'/})
	echo "current_version:$current_version"

	final_version=$(_increment_version $current_version)
	echo "递增后的最终版本号为:$final_version, 正在写入文件..."
#	exit
	content=$(cat $podspecFile)
	content=${content/$current_version/$final_version}

	# 写入文件
	echo "$content" > $podspecFile
}

update_podSpec_source () {
  podSpec_source=$1

}


commit_and_tag (){
	echo -e "\n更新podspec版本号，并打tag..."
	git add .
	git commit -m "自动递增版本号到:$final_version"
	git push
	git tag $final_version;
	git push --tag
	if [[ $? -eq 0 ]]; then
		echo "tag:$final_version 推送成功."
	else
		echo "tag:$final_version 推送失败！！"
		exit 1
	fi
}

#发布pod到cocoapods
# pod trunk push marssdk.podspec
repo_push_to_specs_repo () {
	specsRepoName=$1
	echo "git push to remote..."
	git push --set-upstream origin master
	git push origin

	if [[ $? -eq 0 ]]; then
		echo -e "\n正在发布新版本到ttc_mirror_repo..."
    #    pod ipc spec marssdk.podspec > marssdk.podspec.json
    # 生成json文件
    pod ipc spec $podspecFile > "${podspecFile}.json"
    #推送json配置文件
    pod repo push ttc_mirror_repo "${podspecFile}.json"
		if [[ $? -eq 0 ]]; then
			echo  "git push done!!"
			echo "发布新版本成功(from [${current_version}] to [${final_version}])"
		else
			echo "发布失败!"
		fi
	else
		echo  "git push eorr!"
	fi
	
}

main () {
	pod_lib_lint
	increase_version
	# exit
	commit_and_tag
	# exit
	# 发布到 ttc_mirror_repo
	repo_push_to_specs_repo ttc_mirror_repo
	# # 发布到 cocodpods 官方 repo 上 
	# repo_push_to_specs_repo cocoapods

}


###################### main ######################

main

###################### main ######################




