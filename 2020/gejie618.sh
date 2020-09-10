#!/usr/bin/env bash

source_path="/bi/tmp/gejiecheck/data/";
#source_path="/d/tmp/data/gejie/";
src="/src/";
bad="/bad/";

##################
#压缩文件
##################
compress_name="ET_T_TBL_SUBSCRIBERINFO
ET_T_TBL_ORDEROPERLOG
ET_T_TBL_HW_SQM_ALLSTBINFO
ET_TBL_RUM
ET_SET_REMUNER_INVESTIGA
ET_DICT_REMUNER_ITEMS
ET_TBL_IPTV_CHANNEL
ET_TBL_IPTV_SUBJECT
ET_TBL_PACKAGECONTENT
ET_TBL_PRODUCTINFO
ET_TBL_PRODUCTLANGINFO
ET_TBL_PROGRAM_SUBJECT
ET_TBL_SITCOM_BINDING
ET_TBL_CHANNEL_ATTRIBUTE
ET_TBL_CHANNEL_LANGINFO
ET_TBL_CHANNELHUAWEIMDN
ET_TBL_CHANNELPROGRAMMING
ET_TBL_EPG_ACCESS
ET_TBL_EPG_SUBSCRIBERCDR
ET_TBL_FAVOURITEINFO
ET_TBL_SPINFO
ET_TBL_SUBJECT_AREAS
ET_TBL_SUBJECT_LANGINFO
ET_TBL_SUBNETINFO
ET_TBL_VOD_AREAS
ET_TBL_VOD_ATTRIBUTE
ET_TBL_VODHUAWEIMDN
ET_DAY_USER_PLAY_SOFT"

##################
#错误日志，含部分压缩文件
##################
table_name="ET_MC_BSSAP_RANAP_CDR
ET_DEVICE_USER_INFO
ET_SHARE_LOG
ET_LOGIN_LOG
ET_OTT_TV_ACCOUNT
ET_MKTACT
ET_MIGUVIP_NEWOPEN_MONTH
ET_USE_CLIENT_DETAIL_DAY
ET_T_FNET_REGAF_D
ET_SALES_ANALYSIS_REPORT
ET_WALKMAN_SERVICE_LOG_D
ET_JF_TACHE
ET_TBL_RUM
ET_BASS_4A_ORG
ET_JF_ALLLINE
ET_JF_SHEETINFO
ET_MMUSER_DOWNLOAD_APP_DAY
ET_V_COMPLEXCOMPLAINT_STEP
ET_INTERFACE_CHANNELMETADATA
ET_YUDIANLIVE
ET_TBL_IPTV_CHANNEL
ET_TBL_IPTV_SUBJECT
ET_TBL_PROGRAM_SUBJECT
ET_TBL_CHANNEL_LANGINFO
ET_TBL_CHANNELHUAWEIMDN
ET_TBL_SPINFO
ET_TBL_SUBNETINFO
ET_TBL_VODHUAWEIMDN
ET_EXPOSED_D
ET_GRP_MEM_KEY_USER_M
ET_ORGANIZATION_DEPT
ET_VIEWED_RECORDS
ET_SHARED_RECORDS
ET_ORDER_RECORDS
ET_ICT_PROJECT_MESSAGE
ET_H5_CHNL_DIM
ET_CHNL_SOURCE"

step2_table_name="ET_business_user_list
ET_T_REPORT_INVOICE_DETAIL
ET_RING_MUSIC_BILL_INFO
ET_mr_user_order_detail
ET_2G_CELL
ET_WHOLE_MUSIC_INFO
ET_lucall_prov_04
ET_WLAN_HOT
ET_GSM_CELL_NAME
ET_T_SERVICE_REQUEST_A
ET_lucall_prov_03"

function compress_deal() {
#find /bi/tmp/gejiecheck/data -name *.gz|grep src|awk -F '/' '{print $6}'

targz="tar.gz";
gz=".gz";
zip=".zip";
for file_name in ${compress_name} ; do
    file_path="${source_path}${file_name}${src}";
    file=`ls "${file_path}"`;
#    cd "${source_path}${file_name}${src}";
#    if [[ ${file} == *${targz} ]]; then
#        #原包保留
#        echo "${file_path}${file} is ${targz}"
##        tar -zxvf ${file};
#    elif [[ ${file} == *${gz} ]]; then
#        #原包不保留
#        echo "${file_path}${file} is ${gz}"
##        gunzip ${file};
#    elif [[ ${file} == *${zip} ]]; then
#        #原包保留
#        echo "${file_path}${file} is ${zip}"
##        unzip ${file};
#    else
#        echo "${file_path}${file} type cannot match."
#    fi
    declare -i file_cnt
    file_cnt=0
    for child in ${file} ; do
#        echo "${file_path}${child}";
        if [[ ${child} == *${targz} ]]; then
            #原包保留
            file_cnt=${file_cnt}+1
        elif [[ ${child} == *${gz} ]]; then
            #原包不保留
            file_cnt=${file_cnt}+1
        elif [[ ${child} == *${zip} ]]; then
            #原包保留
            file_cnt=${file_cnt}+1
        fi
    done
    echo "${file_name} file_cnt ${file_cnt}"
done
}

function head_error() {
for file_name in ${step2_table_name} ; do
    file_path="${source_path}${file_name}${bad}"
    if [[ -d ${file_path} ]]; then
        file=`ls ${file_path}*.log`
        if [[ ${file} == "" ]]; then
            echo "${file_path} no log file."
        else
            echo "#####################"
            echo "${file}"|awk -F '/' '{print $6"==="}'
            head -2 ${file}
        fi
    else
        echo "#####################"
        echo "${file_path} dir does not exist."
    fi
done
}

head_error;
