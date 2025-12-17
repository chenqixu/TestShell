# -*- coding: utf-8 -*-

"""
@Time : 2024/11/20
@Author : chenxiaoyong
@File : 标签平台探测
@Description : grep -E 'Cost_time:0.[7-9]|Cost_time:[1-9]' label.str
"""
import requests
from datetime import datetime
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
#import dmPython


#def get_db_connection_pool():
#    conn = dmPython.connect(user='JF00', password='jf00#jf00', server='10.44.84.129', port=5236)
#    return conn


#def get_token(conn):
#    try:
#        cur = conn.cursor()
#        result = cur.execute(
#            'select sub_item_value from drmkt.market_common_item_cfg where item_type = 100013 and SUB_ITEM_TYPE = 1017')
#        token = result.fetchone()[0]
#        cur.close()
#        conn.close()
#        return token
#    except Exception as e:
#        conn.close()


# 初始化数据库连接池和token
#session = get_db_connection_pool()
headers_template = {
    "reqChannelId": "C000201",
    #    "Authorization": get_token(session)
    "Authorization": "QzAwMDIwMTIwMjQxMTIwMDQwMjM1"
    #    "Connection": "close",
    #    "Connection": "keep-alive"
}

# 定义请求地址
url = "http://10.44.130.74:8380/sjkf-label-query-msvc/qryPortrait"
# 定义请求报文
payload_template = {
    "portraitId": "P00000010030",
    "msisdn": "13559164329",
    "queryType": 2
}
# 设置超时时长
timeout = 3
# 定义输出文件路径
output_file = "/bi/user/cqx/shell/str.data"
# 每分钟发送的请求数量
requests_per_minute = 2000
# 并发数
concurrency_level = 50
# 定义每批次的请求数量
batch_size = 100
# 定义每批次休眠时间
batch_sleep_time = 1


def send_request(payload, headers):
    try:
        a = uuid.uuid1().hex
        payload.update({"tags": [a]})
        headers.update({'uuid': a})
        request_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        start_time = time.time()
        response = requests.post(url, json=payload, headers=headers, timeout=timeout)
        response.raise_for_status()
        end_time = time.time()
        cost_time = end_time - start_time
        return f"Uuid:{a}-Request_time:{request_time}-Cost_time:{cost_time:.3f}:seconds-Status:{response.status_code}"
    except requests.exceptions.Timeout:
        print("Request timed out after {} seconds".format(timeout))
    except requests.exceptions.RequestException as e:
        print("An error occurred:", e)


def main():
    with ThreadPoolExecutor(max_workers=concurrency_level) as executor:
        total_requests = requests_per_minute
        batches = [range(i, i + batch_size) for i in range(0, total_requests, batch_size)]
        with open(output_file, "a") as file:
            for batch_idx, batch in enumerate(batches):
                # 记录批次开始时间
                batch_start_time = time.time()
                print(
                    f"Batch {batch_idx + 1} started at {datetime.fromtimestamp(batch_start_time).strftime('%Y-%m-%d %H:%M:%S')}")
                futures = [executor.submit(send_request, payload_template.copy(), headers_template.copy()) for _ in
                           batch]
                for future in as_completed(futures):
                    result = future.result()
                    if result:
                        file.write(result + "\n")
                # 记录批次结束时间
                batch_end_time = time.time()
                batch_duration = batch_end_time - batch_start_time
                batch_sleep_time = 1 - batch_duration
                print(
                    f"Batch {batch_idx + 1} ended at {datetime.fromtimestamp(batch_end_time).strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"Batch {batch_idx + 1} duration: {batch_duration:.2f} seconds. Batch Sleep: {batch_sleep_time:.2f} seconds.")
                # 在每批次完成后休眠
                if batch_sleep_time>0:
                    time.sleep(batch_sleep_time)


if __name__ == "__main__":
    with open(output_file, "a") as file:
        file.write("*" * 20 + "\n")
    start_time = time.time()
    main()
    end_time = time.time()
    elapsed_time = end_time - start_time
    print(f"Total time taken: {elapsed_time:.2f} seconds")