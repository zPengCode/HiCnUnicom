#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# Usage:
## wget --no-check-certificate https://raw.githubusercontent.com/mixool/HiCnUnicom/master/CnUnicom.sh && chmod +x CnUnicom.sh && bash CnUnicom.sh 
### bash <(curl -s https://raw.githubusercontent.com/mixool/HiCnUnicom/master/CnUnicom.sh) ${username} ${password}

# alias curl
alias curl='curl -m 10'

# user info: change them to yours or use parameters instead.
username="$1"
password="$2"

# 联通APP版本
unicom_version=7.0301

# deviceId: 随机IMEI
deviceId=$(shuf -i 123456789012345-987654321012345 -n 1)

# 安卓手机端APP登录过的使用这个UA
UA="Mozilla/5.0 (Linux; Android 6.0.1; oneplus a5010 Build/V417IR; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/52.0.2743.100 Mobile Safari/537.36; unicom{version:android@$unicom_version,desmobile:$username};devicetype{deviceBrand:Oneplus,deviceModel:oneplus a5010}"

# 苹果手机端APP登录过的使用这个UA
#UA="ChinaUnicom4.x/176 CFNetwork/1121.2.2 Darwin/19.2.0"

# workdir
workdir="/root/CnUnicom_$username/"
[[ ! -d "$workdir" ]] && mkdir $workdir

function rsaencrypt() {
    cat > $workdir/rsa_public.key <<-EOF
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDc+CZK9bBA9IU+gZUOc6
FUGu7yO9WpTNB0PzmgFBh96Mg1WrovD1oqZ+eIF4LjvxKXGOdI79JRdve9
NPhQo07+uqGQgE4imwNnRx7PFtCRryiIEcUoavuNtuRVoBAm6qdB0Srctg
aqGfLgKvZHOnwTjyNqjBUxzMeQlEC2czEMSwIDAQAB
-----END PUBLIC KEY-----
EOF

    crypt_username=$(echo -n $username | openssl rsautl -encrypt -inkey $workdir/rsa_public.key -pubin -out >(base64 | tr "\n" " " | sed s/[[:space:]]//g))
    crypt_password=$(echo -n $password | openssl rsautl -encrypt -inkey $workdir/rsa_public.key -pubin -out >(base64 | tr "\n" " " | sed s/[[:space:]]//g))
}

function urlencode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf "$c" | xxd -p -c1 | while read x;do printf "%%%s" "$x";done
        esac
    done
}

# 登录失败尝试修改以下这个appId的值为抓包获取的登录过的联通app
function login() {
    rsaencrypt
    cat > $workdir/signdata <<-EOF
isRemberPwd=true
&deviceId=$deviceId
&password=$(urlencode $crypt_password)
&simCount=0
&netWay=Wifi
&mobile=$(urlencode $crypt_username)
&yw_code: 
&timestamp=$(date +%Y%m%d%H%M%S)
&appId=db5c52929cc2d7f5c46272487e926aebfb82b3bad6b9cd07f1eb99b6a6f34a90
&keyVersion=1
&deviceBrand=Oneplus
&pip=10.0.$(shuf -i 1-255 -n 1).$(shuf -i 1-255 -n 1)
&provinceChanel=general
&version=android%40$unicom_version
&deviceModel=oneplus%20a5010
&deviceOS=android6.0.1
&deviceCode=$deviceId
EOF

    # cookie
    curl -X POST -sA "$UA" -b $workdir/cookie -c $workdir/cookie "https://m.client.10010.com/mobileService/customer/query/getMyUnicomDateTotle.htm?yw_code=&mobile=18593283597&version=android%40$unicom_version" | grep -oE "infoDetail" >/dev/null && status=0 || status=1
    [[ $status == 0 ]] && echo cookies登录$username成功
	
    if [[ $status == 1 ]]; then
        curl -sA "$UA" -D $workdir/cookie "https://m.client.10010.com/mobileService/logout.htm" >/dev/null
        curl -sA "$UA" -b $workdir/cookie -c $workdir/cookie -d @$workdir/signdata "http://m.client.10010.com/mobileService/login.htm" >/dev/null
        token=$(cat $workdir/cookie | grep -E "a_token" | awk  '{print $7}')
        [[ "$token" = "" ]] && echo "Error, login failed." && echo "cmd for clean: rm -rf $workdir" && exit 1
        echo 密码登录$username成功
    fi
}

function openChg() {
    # 每月一号办理解除40G封顶业务
    [[ $(date "+%d") -eq 1 ]] || return 0
    echo; echo $(date) starting dingding OpenChg...
    curl -sA "$UA" -b $workdir/cookie --data "querytype=02&opertag=0" "https://m.client.10010.com/mobileService/businessTransact/serviceOpenCloseChg.htm" >/dev/null
}

function membercenter() {
    echo; echo $(date) starting membercenter...
    
    #获取文章和评论生成数组数据
    NewsListId=($(curl -X POST -sA "$UA" -b $workdir/cookie --data "pageNum=1&pageSize=10&reqChannel=00" https://m.client.10010.com/commentSystem/getNewsList | grep -oE "id\":\"[^\"]*" | awk -F[\"] '{print $NF}' | tr "\n" " "))
    comtId=($(curl -X POST -sA "$UA" -b $workdir/cookie --data "id=${NewsListId[0]}&pageSize=10&pageNum=1&reqChannel=quickNews" -e "https://img.client.10010.com/kuaibao/detail.html?pageFrom=newsList&id=${NewsListId[0]}" https://m.client.10010.com/commentSystem/getCommentList | grep -oE "id\":\"[^\"]*" | awk -F[\"] '{print $NF}' | tr "\n" " "))
    nickId=($(curl -X POST -sA "$UA" -b $workdir/cookie --data "id=${NewsListId[0]}&pageSize=10&pageNum=1&reqChannel=quickNews" -e "https://img.client.10010.com/kuaibao/detail.html?pageFrom=newsList&id=${NewsListId[0]}" https://m.client.10010.com/commentSystem/getCommentList | grep -oE "nickName\":\"[^\"]*" | awk -F[\"] '{print $NF}' | tr "\n" " "))
    Referer="https://img.client.10010.com/kuaibao/detail.html?pageFrom=${NewsListId[0]}"
   
    #评论点赞
    for((i = 0; i < ${#comtId[*]}; i++)); do
        curl -X POST -sA "$UA" -b $workdir/cookie --data "pointChannel=02&pointType=02&reqChannel=quickNews&reqId=${comtId[i]}&praisedMobile=${nickId[i]}&newsId=${NewsListId[0]}" -e "$Referer" https://m.client.10010.com/commentSystem/csPraise
        curl -X POST -sA "$UA" -b $workdir/cookie --data "pointChannel=02&pointType=01&reqChannel=quickNews&reqId=${comtId[i]}&praisedMobile=${nickId[i]}&newsId=${NewsListId[0]}" -e "$Referer" https://m.client.10010.com/commentSystem/csPraise | grep -oE "growScore\":\"0\"" >/dev/null && break
    done
    
    #文章点赞
    for((i = 0; i <= ${#NewsListId[*]}; i++)); do
        curl -X POST -sA "$UA" -b $workdir/cookie --data "pointChannel=01&pointType=02&reqChannel=quickNews&reqId=${NewsListId[i]}" https://m.client.10010.com/commentSystem/csPraise
        curl -X POST -sA "$UA" -b $workdir/cookie --data "pointChannel=01&pointType=01&reqChannel=quickNews&reqId=${NewsListId[i]}" https://m.client.10010.com/commentSystem/csPraise | grep -oE "growScore\":\"0\"" >/dev/null && break
    done
	
    #文章评论
    newsTitle="$(curl -X POST -sA "$UA" -b $workdir/cookie --data "newsId=${NewsListId[1]}&reqChannel=quickNews&isClientSide=0&pageFrom=newsList" -e "$Referer" https://m.client.10010.com/commentSystem/getNewsDetails | grep -oE "mainTitle\":\"[^\"]*" | awk -F[\"] '{print $NF}')"
    subTitle="$(curl -X POST -sA "$UA" -b $workdir/cookie --data "newsId=${NewsListId[1]}&reqChannel=quickNews&isClientSide=0&pageFrom=newsList" -e "$Referer" https://m.client.10010.com/commentSystem/getNewsDetails | grep -oE "subTitle\":\"[^\"]*" | awk -F[\"] '{print $NF}')"
    for((i = 0; i <= 5; i++)); do
        data="id=${NewsListId[1]}&newsTitle=$(urlencode $newsTitle)&commentContent=$RANDOM&upLoadImgName=&reqChannel=quickNews&subTitle=$(urlencode $subTitle)&belongPro=098"
        mycomtId="$(curl -X POST -sA "$UA" -b $workdir/cookie --data "$data" -e "$Referer" https://m.client.10010.com/commentSystem/saveComment | grep -oE "id\":\"[^\"]*" | awk -F[\"] '{print $NF}')"
        curl -X POST -sA "$UA" -b $workdir/cookie --data "type=01&reqId=$mycomtId&reqChannel=quickNews" -e "$Referer" https://m.client.10010.com/commentSystem/delDynamic
    done
    
    #账单查询
    if [[ $(date "+%d") -eq 1 ]]; then
        curl -sLA "$UA" -b $workdir/cookie -c $workdir/cookie.HistoryBill --data "desmobile=$username&version=android@$unicom_version" "https://m.client.10010.com/mobileService/common/skip/queryHistoryBill.htm?mobile_c_from=home" >/dev/null
        curl -sLA "$UA" -b $workdir/cookie.HistoryBill --data "operateType=0&bizCode=1000210003&height=889&width=480" "https://m.client.10010.com/mobileService/query/querySmartBizNew.htm?" >/dev/null
        curl -sLA "$UA" -b $workdir/cookie.HistoryBill --data "systemCode=CLIENT&transId=&userNumber=$username&taskCode=TA52554375&finishTime=$(date +%Y%m%d%H%M%S)" "https://act.10010.com/signinAppH/limitTask/limitTime" >/dev/null
    fi
    
    #签到
    Referer="https://img.client.10010.com/activitys/member/index.html"
    curl -sLA "$UA" -b $workdir/cookie -c $workdir/cookie.SigninActivity -e "$Referer" https://act.10010.com/SigninApp/signin/querySigninActivity.htm >/dev/null
    Referer="https://act.10010.com/SigninApp/signin/querySigninActivity.htm"
    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" "https://act.10010.com/SigninApp/signin/rewardReminder.do?vesion=0.$(shuf -i 1234567890123456-9876543210654321 -n 1)" >/dev/null
    curl -X POST -sA "$UA" -b $workdir/cookie.SigninActivity -e "$Referer" --data "className=signinIndex" https://act.10010.com/SigninApp/signin/daySign.do
    curl -sA "$UA" -b $workdir/cookie.SigninActivity --data "transId=$(date +%Y%m%d%H%M%S)$(shuf -i 0-9 -n 1).$(shuf -i 123456789012345-987654321012345 -n 1)&userNumber=$username&taskCode=TA590934984&finishTime=$(date +%Y%m%d%H%M%S)&taskType=DAILY_TASK" https://act.10010.com/signinAppH/commonTask
    
    ##获取金币
    for((i = 0; i <= ${#NewsListId[*]}; i++)); do
        curl -sA "$UA" -b $workdir/cookie --data "newsId=$(echo "ff808081695a52b1016"$(date +%s%N | md5sum | head -c 13))" "http://m.client.10010.com/mobileService/customer/quickNews/shareSuccess.htm" | grep -oE "jbCount\":\"\"" >/dev/null && break
    done
   
    ##金币抽奖：3 times free each day and 13 times total.
    usernumberofjsp=$(curl -sA "$UA" -b $workdir/cookie.SigninActivity https://m.client.10010.com/dailylottery/static/textdl/userLogin | grep -oE "encryptmobile=\w*" | awk -F"encryptmobile=" '{print $2}'| head -n1)
    for((i = 1; i <= 3; i++)); do
        [[ $i -gt 3 ]] && curl -sA "$UA" -b $workdir/cookie.SigninActivity --data "goldnumber=10&banrate=10&usernumberofjsp=$usernumberofjsp" https://m.client.10010.com/dailylottery/static/doubleball/duihuan >/dev/null; sleep 1
        curl -sA "$UA" -b $workdir/cookie.SigninActivity --data "usernumberofjsp=$usernumberofjsp" https://m.client.10010.com/dailylottery/static/doubleball/choujiang | grep -oE "用户机会次数不足" >/dev/null && break
    done
    echo goldTotal：$(curl -sA "$UA" -b $workdir/cookie.SigninActivity "https://act.10010.com/SigninApp/signin/goldTotal.do")
}

function main() {
    #sleep $(shuf -i 1-10800 -n 1)
    login
    membercenter
    openChg
    #rm -rf $workdir
    echo; echo $(date) $username Accomplished.  Thanks!
}

main
