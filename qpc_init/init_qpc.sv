// ==============================================================
//  task init_qpc  – QPC 初始化 (seg 3~16，排除 rsv 字段和初始值为空的字段)
//  来源 : 天蝎RDMA数据结构v3.83.xlsx  Sheet: QPC
//  生成字段数: 458
//  范围: seg 3 ~ 16 (跳过 seg 0,1,2)
// ==============================================================

task init_qpc(
    ref rdma_rxe_qpc_entends hca_qpc,
    input bit                  veroce_en
);

    // ── seg 03 ──
    hca_qpc.qpc_seg3.qp_ud_sqer2rts_phase_flag = '0;  // 当软件发送的Modify命令为SQEr2RTS时取反该信号
    hca_qpc.qpc_seg3.qp_rc_sqd2rts_phase_flag = '0;  // 当软件发送的Modify命令为SQD2RTS时取反该信号
    hca_qpc.qpc_seg3.qp_destroy_flag = '0;  // 当前QP执行过QP销毁，未创建执行modify或重复销毁操作则会报错
    hca_qpc.qpc_seg3.sq_cq_overflow_flag = '0;  // SQ绑定的CQ溢出时，该标志置1，如果SQ和RQ绑定同一个CQ，则sq_cq_overflow_flag和rq_cq_overflow_flag同时置1（MQ_PROC在创建QP或INIT2RTR时初始化成0，后续由CQEQ_PROC管理）
    hca_qpc.qpc_seg3.rq_cq_overflow_flag = '0;  // RQ绑定的CQ溢出时，该标志置1，如果SQ和RQ绑定同一个CQ，则sq_cq_overflow_flag和rq_cq_overflow_flag同时置1（MQ_PROC在创建QP或INIT2RTR时初始化成0，后续由CQEQ_PROC管理）

    // ── seg 04 ──
    hca_qpc.qpc_seg4.txwqe_sq_err = '0;  // 在检测到需要sq 错误时置1 在检测到 MQ qp_ud_sqer2rts_phase_flag != txwqe_ud_sqer2rts_phase_flag时将txwqe_sq_err清0
    hca_qpc.qpc_seg4.txwqe_rq_err = '0;
    hca_qpc.qpc_seg4.txwqe_rtr2rts_flag = '0;
    hca_qpc.qpc_seg4.txwqe_rts2sqd_phase_flag = '0;  // txwqe rts2sqd 状态的检测，在txwqe_sqd_state为0时，检测到rxi 进入到sqd 状态，或者tx 发送点超过了出错点的wqe，将txwqe_sqd_state置1，同时翻转该信号
    hca_qpc.qpc_seg4.txwqe_sqd_state = '0;  // 指示txwqe 已经进入到sqd 状态，停止发包
    hca_qpc.qpc_seg4.txwqe_qp_destroy = '0;  // txwqe内部之前发生过销毁事件
    hca_qpc.qpc_seg4.txwqe_qp_reset = '0;  // txwqe内部之前发生过reset事件
    hca_qpc.qpc_seg4.txwqe_fatal_err = '0;  // txwqe内部发生过不能flush的错误，已发送给txeng上报异步事件
    hca_qpc.qpc_seg4.txwqe_dif_err_phase_tag = '0;  // 出现dif err时，完成flush后，同步rxi_dci_err_phase_flag
    hca_qpc.qpc_seg4.txwqe_ctrl_info_cnt = '0;  // txwqe每处理一个qp index有效的ctrl info则++，计满翻转；主要是在sl2vl 动态切换时使用
    hca_qpc.qpc_seg4.txwqe_cur_cos = '0;  // 记录当前调度所属的cos，在cos切换时需要比较txwqe_ctrl_info_cnt和txeng_ctrl_info_cnt是否相等，决定是否执行当前门铃处理；解决sl2vl 动态切换时乱序的问题
    hca_qpc.qpc_seg4.txwqe_sqd2rts_phase_flag = '0;  // 从sqd 切回rts 的状态同步，在检测到qp_rc_sqd2rts_phase_flag !=txwqe_sqd2rts_phase_flag 时翻转该信号；同时将 txwqe_sqd_state 清零； 同时将txwqe_hw_rts2sqd_phase_tag 同步成rxi_hw_rts2sqd_phase_flag一样的状态（避免在切rts 时 sq 已经为空，该装态没能及时同步）
    hca_qpc.qpc_seg4.txw_rate_timestamp_l = '0;  // 每次发送时刷新当前的时间戳低32位
    hca_qpc.qpc_seg4.txw_rate_timestamp_h = '0;  // 每次发送时刷新当前的时间戳高32位
    hca_qpc.qpc_seg4.txw_end_disp_reason = '0;  // 回挂门铃的原因，方便debug，例如ssnt受限，nowqe，err等具体编码 详见WQE的MAS文档
    hca_qpc.qpc_seg4.txw_cq_sq_overflow_flag = '0;  // 置1：获取过sq_overflow的信息
    hca_qpc.qpc_seg4.txw_cq_rq_overflow_flag = '0;  // 置1：获取过rq_overflow的信息
    hca_qpc.qpc_seg4.txw_sq_cur_path_id = '0;  // SQ当前使用的path 号，在做速率控制时控制使用哪种path的参数；在非多路径模式下，固定为0；在多路径模式下，在当前对应path 令牌消耗完毕后path_id ++，或者在一次DB调度结束后path_id ++ （仅代表rq 报文处理）
    hca_qpc.qpc_seg4.txw_sq_path_mask = '0;  // 为1代表SQ在端侧乱序模式下，锁定当前路径时，DB调度时，出现了令牌桶受限的场景；当调度到SQ门铃时，且此时令牌桶不受限，清除此位。
    hca_qpc.qpc_seg4.txwqe_stat_rate_already_init = '0;  // 0:没有初始化过静态速率，1：初始化过静态速率。
    hca_qpc.qpc_seg4.txwqe_sq_wqe_occupty = '0;  // SQ门铃敲入时发现信用不够，不能响应本次请求，txw_sq_occupty置位1，下次如果是RESP门铃，resp门铃不执行。当sq门铃敲入时，如果令牌充足，这个标志会清0。
    hca_qpc.qpc_seg4.txwqe_rsp_occupty = '0;  // 标识当前调度需要服务response 门铃，如果遇到sq 门铃直接回挂。
    hca_qpc.qpc_seg4.txwqe_ud_sqer2rts_phase_flag = '0;  // sqer2rts 切换的phase标记；在检测到 MQ qp_ud_sqer2rts_phase_flag != txwqe_ud_sqer2rts_phase_flag时进行翻转；同时将txwqe_sq_err清0
    hca_qpc.qpc_seg4.txwqe_rc_sq_flush_flag = '0;  // rc模式下sq 进入flush的标记，在检测到qpc.rxi_qp_state_err_flag为1时，rxi 指示的wrid 打err 标记发送给tx eng，后续wqe 打flush type；在该次调度结束将该信号置1；后续调度发送给tx eng均打flush 标记；flush 后在qp重启时由MQ 清零
    hca_qpc.qpc_seg4.txwqe_sw_qp_err_flag = '0;  // 在检测到软件片的qp_state为error时将该信号拉高，表示检测到软件modify qp到error装态，只有在qp重新初始化时清0
    hca_qpc.qpc_seg4.txwqe_path0_rtt_prob_phase_tag = '0;  // 在swcc qp 模式下和CC 模块同步是否需要发送rtt_prob 报文的同步信号 在txwqe_path0_rtt_prob_phase_tag != cc_path0_rtt_prob_phase_tag 时代表path0 需要发送rtt_prob 报文，发送后将phase_tag 取反
    hca_qpc.qpc_seg4.txwqe_path1_rtt_prob_phase_tag = '0;  // 在swcc qp 模式下和CC 模块同步是否需要发送rtt_prob 报文的同步信号 在txwqe_path1_rtt_prob_phase_tag != cc_path1_rtt_prob_phase_tag 时代表path1 需要发送rtt_prob 报文，发送后将phase_tag 取反
    hca_qpc.qpc_seg4.txwqe_path2_rtt_prob_phase_tag = '0;  // 在swcc qp 模式下和CC 模块同步是否需要发送rtt_prob 报文的同步信号 在txwqe_path2_rtt_prob_phase_tag != cc_path2_rtt_prob_phase_tag 时代表path2 需要发送rtt_prob 报文，发送后将phase_tag 取反
    hca_qpc.qpc_seg4.txwqe_path3_rtt_prob_phase_tag = '0;  // 在swcc qp 模式下和CC 模块同步是否需要发送rtt_prob 报文的同步信号 在txwqe_path3_rtt_prob_phase_tag != cc_path3_rtt_prob_phase_tag 时代表path3 需要发送rtt_prob 报文，发送后将phase_tag 取反
    hca_qpc.qpc_seg4.txwqe_dip_mode_rtt_prob_flag = '0;  // 在swcc DIP模式下使用，初始值为0 在load 到 ccc context后发现，由于没有令牌/窗口，不能执行wqe时，将ccc 中的rrt_prob_flag 同步过来，在通知txeng 发送 rtt probe 报文后清零
    hca_qpc.qpc_seg4.txwqe_rq_cur_path_id = '0;  // RQ当前使用的path 号，在做速率控制时控制使用哪种path的参数；在非多路径模式下，固定为0；在多路径模式下，在当前对应path 令牌消耗完毕后path_id ++，或者在一次DB调度结束后path_id ++ （仅代表rq 报文处理）
    hca_qpc.qpc_seg4.txw_path0_rate_bucket = '0;  // path0 令牌桶，初始化时根据Bucket Type将桶填满，以B为单位，负值以补码形式; 多路径时 path0的令牌桶，非多路径时也使用这个令牌桶
    hca_qpc.qpc_seg4.txw_path1_rate_bucket = '0;  // path0 令牌桶，初始化时根据Bucket Type将桶填满，以B为单位，负值以补码形式; 多路径时 path1的令牌桶，非多路径时也使用这个令牌桶
    hca_qpc.qpc_seg4.txw_path2_rate_bucket = '0;  // path0 令牌桶，初始化时根据Bucket Type将桶填满，以B为单位，负值以补码形式; 多路径时 path2的令牌桶，非多路径时也使用这个令牌桶
    hca_qpc.qpc_seg4.txw_path3_rate_bucket = '0;  // path0 令牌桶，初始化时根据Bucket Type将桶填满，以B为单位，负值以补码形式; 多路径时 path3的令牌桶，非多路径时也使用这个令牌桶
    hca_qpc.qpc_seg4.txw_path_disable_flag = '0;  // 记录是否发生过path_disable的事件，此值为高时，令牌桶为负值22'h20_0000，不再使用此路径调度，若seg.path_disable为0，需要初始化此桶深为寄存器基于function配置的压缩比值。

    // ── seg 05 ──
    hca_qpc.qpc_seg5.txwqe_sq_wqe_ci = '0;  // sqe硬件读指针，64B为单位，指向当前wqe的头位置，初始值为0
    hca_qpc.qpc_seg5.txwqe_sq_wqe_pi = '0;
    hca_qpc.qpc_seg5.txwqe_sq_send_npsn = sw.send_start_psn;  // 发送请求psn号
    hca_qpc.qpc_seg5.txwqe_sq_send_pkt_flag = '0;  // 从别的状态进入到这两个状态RTS，SQD中的任何一个状态已经调度过：决定txwqe中sq的初始化。
    hca_qpc.qpc_seg5.txwqe_sq_pref_wqe_flag = '0;  // 曾经预取过sqe放到sqe cache中，用于收到llwqe时是否需要销毁sqe cache中的数据
    hca_qpc.qpc_seg5.txwqe_sq_local_ds = '0;  // 最近最新处理完成local操作所对应的ds值，对齐成64B为单位
    hca_qpc.qpc_seg5.txwqe_sq_ssn = hca_qpc.start_ssn;  // ssn; 信用控制
    hca_qpc.qpc_seg5.txwqe_sq_local_ssn_0 = '0;  // 最近最新处理完成local操作所对应的ssn[7:0]值，和local wqe的下一个wqe的ssn编号相同
    hca_qpc.qpc_seg5.txwqe_sq_lsn = hca_qpc.start_ssn-1;  // lsn; 信用控制
    hca_qpc.qpc_seg5.txwqe_sq_local_ssn_1 = '0;  // 最近最新处理完成local操作所对应的ssn[15:8]值，和local wqe的下一个wqe的ssn编号相同
    hca_qpc.qpc_seg5.txwqe_sq_wqe_start_psn = sw.send_start_psn;  // WQE起始PSN，重传阶段保持不变。
    hca_qpc.qpc_seg5.txwqe_sq_local_ssn_2 = '0;  // 最近最新处理完成local操作所对应的ssn[23:16]值，和local wqe的下一个wqe的ssn编号相同
    hca_qpc.qpc_seg5.txwqe_sq_page_pa_vld = '0;  // 二级PBL模式两个Sqe4K页首地址有效标识
    hca_qpc.qpc_seg5.txwqe_sq_page_pa_sel = '0;  // 二级PBL模式两个Sqe4K页首地址选择标识
    hca_qpc.qpc_seg5.txwqe_sq_bk_vld = '0;  // sq发送时wqe 断点有效，默认值为0，仅在正在发送时有效。
    hca_qpc.qpc_seg5.txwqe_sq_bk_sge_addr = '0;  // sq发送时wqe断点，需要执行sge在wqe内部的偏移，wqe断点sge块偏移地址，单位16Byte
    hca_qpc.qpc_seg5.txwqe_sq_bk_rsp_ptr = '0;  // sq发送时，如果是read操作，所需要携带的对端rsp cache的指针，每发送一个read++，也是控制read的outstanding的个数的写指针
    hca_qpc.qpc_seg5.txwqe_sq_bk_irbk_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // sq发送时，如果是read操作，所需要携带的irbk的指针，每次更换sge就++，也是控制read的outstanding的个数的剩余空间判断条件之一
    hca_qpc.qpc_seg5.txwqe_sq_dif_bk_sge_addr = '0;  // sq发送时dif wqe断点，需要执行sge dif在wqe内部的偏移，wqe断点sge块偏移地址，单位16Byte；VeRoCE下复用为loca操作的opcode的低5bit，高位不用记录，直接tie0
    hca_qpc.qpc_seg5.txwqe_sq_page_pa1 = '0;  // 二级PBL模式Sqe4K页首地址1
    hca_qpc.qpc_seg5.txwqe_sq_page_pa2 = '0;  // 二级PBL模式Sqe4K页首地址2
    hca_qpc.qpc_seg5.txwqe_sq_bk_sge_ofs = '0;  // sq重发送时wqe断点，需要执行数据在sge内的偏移
    hca_qpc.qpc_seg5.txwqe_sq_req_sack_retry_cnt = '0;  // 当和rxi 的sack cnt不相等时可能需要有选择性重传（tmo和rnr该cnt 不反转）
    hca_qpc.qpc_seg5.txwqe_sq_req_rqeth_msn = '0;  // VeRoCE下rqmsn，rqe的index，即请求报文中的RQETH中的RQMSN
    hca_qpc.qpc_seg5.txwqe_sq_retry_phase_tag = '0;  // wqe维护的nak重传标识，rxi_retry_phase_tag!=txwqe_sq_retry_phase_tag时，RXI端发起重传； 当rxi_req_rnr_retry_flag==0时，为NAK重传； 当rxi_req_rnr_retry_flag==1时，为RNR重传； 重传位置由rxi_ssnt_wqe_wrid指定.
    hca_qpc.qpc_seg5.txwqe_sq_retry_flag = '0;  // SQ重传指示，高电平期间的WQE都属于重传。Veroce 重传需要使用，表示正在重传（包含sack和go back N重传）
    hca_qpc.qpc_seg5.txwqe_sq_retry_type = '0;  // 记录的重传类型，用做重传超限的计数判断。1:RNR重传  0:NAK重传
    hca_qpc.qpc_seg5.txwqe_sq_nak_retry_cnt = '0;  // 本地维护的NAK重传次数,用作重传超限判断。
    hca_qpc.qpc_seg5.txwqe_sq_rnr_retry_cnt = '0;  // 本地维护的RNR重传次数,用作重传超限判断。
    hca_qpc.qpc_seg5.txwqe_sq_retry_noctrl_to_txeng = '0;  // 启动重传后，标识还未给txeng发送重传起始标记。若有ctrl info发给txeng需要打标start_retry标记，同时拉低此位。或者退出重传时拉低此位。
    hca_qpc.qpc_seg5.txwqe_sq_bkn_retry_flag = '0;  // Veroce 重传使用，txwqe_sq_retry_flag为高时有效，表示正在进行go back N的重传
    hca_qpc.qpc_seg5.txwqe_sq_retry_wqe_idx = '0;  // sq重传时需要发送wqe对应首个wqebb的 idex 在重传开始，从rxi的qpc中copy过来（rxi_ssnt_wqe_wrid），后续重传过程中自己维护 首次重传，除了需要使用rxi_ssnt_wqe_idx，还需要使用，rxi_ssnt_wqe_start_psn和rxi_ssnt_wqe_data_length来计算wqe内部sge及其data的偏移。Veroce场景下同retry_psn的使用方式
    hca_qpc.qpc_seg5.txwqe_sq_wqe_sq_retry_psn = '0;  // sq重传时需要发送的psn号，wqe自己维护 Veroce场景下，该psn 还有指示重传能够开始的位置，即在两次重传时间间隔小于配置值时从该位置开始重传，在大于该时间或者是RNR/TMO超时从un ack psn开始重传，同时将该信号回退到unack psn
    hca_qpc.qpc_seg5.txwqe_sq_local_wrid_0 = '0;  // 最近最新处理完成local操作所对应的wrid[7:0]值
    hca_qpc.qpc_seg5.txwqe_sq_retry_start_psn = '0;  // 记录的重传起始psn，用做重传超限的计数判断。如果当前重传的起始PSN和txw_sq_retry_start_psn相等为相同重传。
    hca_qpc.qpc_seg5.txwqe_sq_local_wrid_1 = '0;  // 最近最新处理完成local操作所对应的wrid[15:8]值
    hca_qpc.qpc_seg5.txwqe_sq_retry_bk_irbk_ptr = '0;  // sq重传时，如果时read重传，所需要携带的irbk的指针 首次重传需要从rxi的qpc中snnt的irbk指针结合wqe 扫描获取；
    hca_qpc.qpc_seg5.txwqe_sq_retry_bk_rsp_ptr = '0;  // sq重传时，如果时read重传，所需要携带的对端rsp cache的指针 首次重传需要从rxi的qpc中snnt的rsp ptr计算获取
    hca_qpc.qpc_seg5.txwqe_sq_ssnt_wr_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // txwqe记录的当前发送的ssnt的写指针，用作message的outstanding个数计算
    hca_qpc.qpc_seg5.txwqe_sq_local_ce = '0;  // 最近最新处理完成local操作所对应的CE
    hca_qpc.qpc_seg5.txwqe_sq_retry_end_psn = '0;  // SQ重传的终点PSN，重传范围不包含该PSN。
    hca_qpc.qpc_seg5.txwqe_sq_retry_bk_sge_addr = '0;  // sq重传时wqe断点，需要执行sge在wqe内部的偏移 首次重传，除了需要使用rxi_ssnt_wqe_idx，还需要使用，rxi_ssnt_wqe_start_psn和rxi_ssnt_wqe_data_length来计算wqe内部sge及其data的偏移
    hca_qpc.qpc_seg5.txwqe_sq_retry_bk_vld = '0;  // sq重传时wqe 断点有效
    hca_qpc.qpc_seg5.txwqe_sq_local_phase_flag = '0;  // 和rx eng配合控制local操作的outstanding，在和rx eng的phase相等时碰到的local操作可以处理，处理之后翻转phase，同时记录改local操作的信息，否则回挂空门铃
    hca_qpc.qpc_seg5.txwqe_sq_local_opcode_fence_flag = '0;  // Veroce 下使用，表示当前处于local fence状态 在处理到local 操作，且local_phase_tag 和rxeng的不等，将该信号置1，在local_phase_tag相同时清0；在sq执行如果local_fence_flag为高，且local_phase_tag不同时直接回挂空门铃。
    hca_qpc.qpc_seg5.txwqe_sq_retry_bk_sge_ofs = '0;  // sq重传时wqe断点，需要执行数据在sge内的偏移 首次重传，除了需要使用rxi_ssnt_wqe_idx，还需要使用，rxi_ssnt_wqe_start_psn和rxi_ssnt_wqe_data_length来计算wqe内部sge及其data的偏移
    hca_qpc.qpc_seg5.txwqe_sq_req_read_psn = sw.send_start_psn;  // 用于做response 侧8M psn outstanding的控制，用作I端read 长超时qp置错使用，该psn为当前read、atomic发送后移动到psn的位置，初始值SEG0.send_start_psn
    hca_qpc.qpc_seg5.txwqe_sq_nxt_wqe_psn = '0;  // 下一个WQE占用的psn个数，PSN范围检查失败的时候更新，下次在QPC检查时进行预判断.  Veroce 时遇到read 请求，记录的就是read 占用response psn的数量，在做psn检查时需要既做req 请求8M范围的检查，又要做response 8M范围的检查，和nxt_wqe_type配合一起使用
    hca_qpc.qpc_seg5.txwqe_sq_retry_psn_vld = '0;  // Veroce 重传结束后，置1，代表当前重传断点有效，若txwqe_sq_dif_bk_sge_ofs（timer)记录的时间和系统时间超过某一个阈值（寄存器可配，默认值为40us）后，或者是txwqe_sq_wqe_sq_retry_psn在rxi_sq_oldest_unack_psn左侧或者相等，置0；
    hca_qpc.qpc_seg5.txwqe_sq_nxt_wqe_type = '0;  // Veroce 下使用，标注下一个wqe 的类型；0x0 表示下一个wqe类型为非read/atomic；0x1表示下一个wqe类型非为read/atomic；在PSN范围检查时使用，下次在qpc检查时进行预判断
    hca_qpc.qpc_seg5.txwqe_sq_nxt_need_irrl_num = '0;  // 下一个read/atomic携带sge个数,wqe_outsdanding_check_en有效时使用。
    hca_qpc.qpc_seg5.txwqe_sq_psn_check_en = '0;  // psn有效范围超限导致跳过sq处理，下次qp调度满足该条件后获取wqe
    hca_qpc.qpc_seg5.txwqe_sq_path_need_lock = '0;  // ooo_enabled开启时，multi_path_id_replace_sel为1或者2时，此时若已经发送的wqe是需要send/write with imme only/atomic/write with imme last，需要置位；当所有ack返回时，需要清除此位
    hca_qpc.qpc_seg5.txwqe_sq_read_fence_check_en = '0;  // read fence上次检查不通过，QPC检查时先做判断。
    hca_qpc.qpc_seg5.txwqe_sq_local_fence_check_en = '0;  // local fence上次检查不通过，QPC检查时先做判断。
    hca_qpc.qpc_seg5.txwqe_sq_ooo_fence_en = '0;  // ooo_enabled开启时，SQ处理时发现需要fence的message或者是pascket，拉高此位，等待所有应答全部返回，拉低此位。
    hca_qpc.qpc_seg5.txwqe_sq_chk_st = '0;  // 记录QPC检查之后确定的工作状态。
    hca_qpc.qpc_seg5.txwqe_sq_credit_check_en = '0;  // 信用检查导致跳过sq处理，下次qp调度满足该条件后获取wqe
    hca_qpc.qpc_seg5.txwqe_sq_outsdanding_check_en = '0;  // read/atomic在途sge个数导致跳过sq处理，下次qp调度满足该条件后获取wqe
    hca_qpc.qpc_seg5.txwqe_sq_bk_block = '0;  // dif模式下，正常wqe发送时，计算dif个数的block断点长度，sq_bk_vld为高时有效： Veroce模式下：txwqe_sq_retry_rqeth_msn[12:0]，重传的rqmsn，rqe的index，即请求报文中的RQETH中的RQMSN
    hca_qpc.qpc_seg5.txwqe_sq_retry_bk_block = '0;  // dif模式下，重传wqe发送时，计算dif个数的block断点长度，sq_bk_vld为高时有效； Veroce模式下：低11bit为txwqe_sq_retry_rqeth_msn[23:13]，重传的rqmsn，rqe的index，即请求报文中的RQETH中的RQMSN，剩余2bit为rsv
    hca_qpc.qpc_seg5.txwqe_sq_retry_wqe_start_psn = '0;  // 重传期间当前正在处理的wqe的起始psn
    hca_qpc.qpc_seg5.txwqe_sq_retry_end_wrid_0 = '0;  // Veroce复用为重传预取到的wrid[7:0]，VeRoCE下预取到的wrid的值，当重传结束的时候，需要把多预取的wqe invalid掉
    hca_qpc.qpc_seg5.txwqe_sq_retry_ssn = '0;  // 重传期间当前正在wqe的ssn，或者是处理完成后的下一个wqe的ssn
    hca_qpc.qpc_seg5.txwqe_sq_retry_end_wrid_1 = '0;  // Veroce复用为重传预取到的wrid[15:8]，VeRoCE下预取到的wrid的值，当重传结束的时候，需要把多预取的wqe invalid掉
    hca_qpc.qpc_seg5.txwqe_sq_dif_bk_sge_ofs = '0;  // sq发送时dif wqe断点，需要执行的dif在sge内的偏移；veroce 下复用为timestamp，us为单位；上次重传点的信息是否有效的。重传结束时更新。

    // ── seg 06 ──
    hca_qpc.qpc_seg6.txwqe_rsp_newest_psn = hca_qpc.qpc_seg00.rcv_start_psn-1;  // resp/ack/nak调度完成的最新psn号， 非乱序时，txt_resp_newest_psn != rxt_resp_newest_psn时，表示有新的ack/nak/response未发送。 乱序时，txt_resp_newest_psn != (rxt_resp_left_psn-1)时，表示有新的ack/nak/response未发送。 veroce下复用为read/atomic response发送占用的psn号，处理方式和sq的处理方式保持一致
    hca_qpc.qpc_seg6.txwqe_rsp_debug = '0;
    hca_qpc.qpc_seg6.txwqe_rsp_max_rd_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // read rsp的指针右边界，每发送一笔normal resp的last/only报文后更新，不回退，同时用于rxt判断read ost
    hca_qpc.qpc_seg6.txwqe_rsp_cur_rd_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // read rsp实时正在执行的rsp cache指针，受重传影响会回退，执行normal resp时与max ptr同步推进； veroce下复用重传断点的指针
    hca_qpc.qpc_seg6.txwqe_rsp_retry_start_ptr = '0;  // read rsp重传起始点的rsp cache指针，当txwqe_rsp_retry_cnt与rxt_rsp_retry_cnt不相等时，同步为rxt_rsp_retry_start_ptr
    hca_qpc.qpc_seg6.txwqe_rsp_retry_end_ptr = '0;  // read rsp重传结束点的rsp cache指针，同步为rxt_rsp_retry_end_ptr
    hca_qpc.qpc_seg6.txwqe_rsp_retry_cnt = '0;  // 判断是否有新的rsp 重传范围；初始值为0，在检测到rxt_rsp_retry_cnt != txwqe_rsp_retry_cnt时进入新的重传，同时将 txwqe_rsp_retry_cnt刷新成rxt_rsp_retry_cnt的值； veroce下由于sack引发的重传，和rxt_sel_retry_cnt比较
    hca_qpc.qpc_seg6.txwqe_rsp_bk_whole_vld = '0;  // read rsp存储的完整断点信息有效指示信号，在读取resp entry之后，校验长度发现信用一个报文都不够发送，则完整记录这个entry，重传时，完整的rsp断点，发送opcode受go bak n影响，非完整的rsp断点，不受go bak n影响，normal时，完整的rsp从first/only处发送，非完整的从middle/last处发送；
    hca_qpc.qpc_seg6.txwqe_rsp_bk_vld = '0;  // read rsp存储的断点信息有效指示信号，在没有消耗完一个rsp cache时需要置1，标记下一次从rsp cache中间执行
    hca_qpc.qpc_seg6.txwqe_rsp_retry_psn_vld = '0;  // Veroce 重传结束后，置1，代表当前重传断点有效，若txwqe_rsp_retry_bk_dif_sge_ofs记录的时间和系统时间超过某一个阈值（寄存器可配，默认值为40us）后，或者是txwqe_rsp_retry_bk_psn在rxt_rsp_left_psn的左侧或者相等，置0。
    hca_qpc.qpc_seg6.txwqe_rsp_retry_flag = '0;  // rsp 重传指示，在整个rsp的重传过程中为1，初始值为0；在检测到rxt_rsp_retry_cnt != txwqe_rsp_retry_cnt时进入重传，并将该信号置1； 在重传结束之后，将该信号清零
    hca_qpc.qpc_seg6.txwqe_rsp_err = '0;  // 记录是否发生过response读取错误，0：没有发生过  1：发生过读取response错误的事件。
    hca_qpc.qpc_seg6.txwqe_ack_retry_phase_tag = '0;  // T端请求命令的ack应答，在txwqe_ack_retry_flag != rxt_ack_retry_flag时进行ack重传操作；重传完毕后翻转
    hca_qpc.qpc_seg6.txwqe_nak_phase_tag = '0;  // 当rxt_nak_flag !=txwqe_nak_phase_tag成立时，触发NAK包发送。
    hca_qpc.qpc_seg6.txwqe_rsp_retry_bk_vld = '0;  // read rsp存储的重传断点信息有效指示信号，在没有消耗完一个rsp cache时需要置1，标记下一次从rsp cache中间执行
    hca_qpc.qpc_seg6.txwqe_rsp_retry_go_bak_n = '0;  // 记录resp重传的go_back_n标志，response被断点时会被更新，txwqe_rsp_retry_bk_whole_vld有效时才有意义。
    hca_qpc.qpc_seg6.txwqe_rsp_ack_retry_phase_tag = '0;  // I端的read resp的ack应答flag，在 txwqe_rsp_ack_retry_phase_tag!=rxi_rsp_ack_retry_phase_flag时进行ack重传操作；重传完毕后翻转（I端重传ACK标记）
    hca_qpc.qpc_seg6.txwqe_rsp_ack_psn_init_flag = '0;  // Veroce下完成对txwqe_rsp_ack_psn的初始化
    hca_qpc.qpc_seg6.txwqe_rsp_tmo_retry_cnt = '0;  // Veroce下回复read resp重传超限的cnt，默认值为0
    hca_qpc.qpc_seg6.txwqe_rsp_bk_psn = hca_qpc.qpc_seg00.rcv_start_psn-1;  // read rsp存储的断点信息中的psn号，在获取rsp cache时，初始psn需要从rsp cache中获取，执行rsp cache sge中间需要从该处获取发送psn号; [23:0]veroce下为T端ack响应的psn号
    hca_qpc.qpc_seg6.txwqe_req_sack_send_retry_cnt = '0;  // veroce下T端在同一个PSN点回复sack的次数，每次刷新txwqe_rsp_bk_psn就清0，当同一个psn的重传次数达到某一个值（txwqe内部寄存器配置，默认8），就不再响应相同psn点的sack
    hca_qpc.qpc_seg6.txwqe_rsp_bk_len = '0;  // read rsp存储的断点信息中的长度信息，在获取rsp cache时，初始len需要从rsp cache中获取，发送部分报文后，根据已发送的长度推进更新
    hca_qpc.qpc_seg6.txwqe_rsp_bk_data_sge_addr = '0;  // rsq normal发送时dif wqe断点，需要执行sge data在wqe内部的偏移，wqe断点sge块偏移地址，单位16Byte
    hca_qpc.qpc_seg6.txwqe_rsp_bk_dif_sge_addr = '0;  // rsq normal发送时dif wqe断点，需要执行sge dif在wqe内部的偏移，wqe断点sge块偏移地址，单位16Byte
    hca_qpc.qpc_seg6.txwqe_rsp_bk_block = '0;  // rsq normal发送时dif wqe断点，上一次pmtu插入dif后剩余block大小
    hca_qpc.qpc_seg6.txwqe_rsp_bkn_retry_flag = '0;  // veroce 下代表正在进行的是go back to N的重传
    hca_qpc.qpc_seg6.txwqe_rsp_sack_send_cnt = '0;  // I端sack cnt，和rxi 的sack cnt不相等时有可能会有sack的发送，在ack eng处理结束后刷新成为rxi一样的值
    hca_qpc.qpc_seg6.txwqe_rsp_bk_data_sge_ofs = veroce_en ? hca_qpc.start_ssn-1 : '0;  // rsq发送时dif wqe断点，需要执行的数据在sge内的偏移 bit[23:0]veroce下为发送read/atomic 记录的MSN号
    hca_qpc.qpc_seg6.txwqe_rsp_bk_dif_sge_ofs = '0;  // rsq发送时dif wqe断点，需要执行的dif在sge内的偏移； bit[23:0]veroce下txwqe_rsp_tmo_retry_psn引发重传点的psn。
    hca_qpc.qpc_seg6.txwqe_cnp_timestamp = '0;  // 上一次调度cnp报文的时间戳，单位us
    hca_qpc.qpc_seg6.txwqe_path0_txt_cnp_phase_tag = '0;  // path0 上一次响应rxt的cnp调度时同步的rxt_cnp_flag
    hca_qpc.qpc_seg6.txwqe_path0_txi_cnp_phase_tag = '0;  // path0 上一次响应rxi的cnp调度时同步的rxi_cnp_flag
    hca_qpc.qpc_seg6.txwqe_path1_txt_cnp_phase_tag = '0;  // path1 上一次响应rxt的cnp调度时同步的rxt_cnp_flag
    hca_qpc.qpc_seg6.txwqe_path1_txi_cnp_phase_tag = '0;  // path1 上一次响应rxi的cnp调度时同步的rxi_cnp_flag
    hca_qpc.qpc_seg6.txwqe_path2_txt_cnp_phase_tag = '0;  // path2 上一次响应rxt的cnp调度时同步的rxt_cnp_flag
    hca_qpc.qpc_seg6.txwqe_path2_txi_cnp_phase_tag = '0;  // path2 上一次响应rxi的cnp调度时同步的rxi_cnp_flag
    hca_qpc.qpc_seg6.txwqe_path3_txt_cnp_phase_tag = '0;  // path3 上一次响应rxt的cnp调度时同步的rxt_cnp_flag
    hca_qpc.qpc_seg6.txwqe_path3_txi_cnp_phase_tag = '0;  // path3 上一次响应rxi的cnp调度时同步的rxi_cnp_flag
    hca_qpc.qpc_seg6.txwqe_rsp_retry_bk_psn = '0;  // read rsp重传存储的断点信息中的psn号，在获取rsp cache时，初始psn需要从rsp cache中获取，执行rsp cache sge中间需要从该处获取发送psn号； veroce下复用重传断点的psn
    hca_qpc.qpc_seg6.txwqe_rsp_retry_bk_len = '0;  // read rsp重传存储的断点信息中的长度信息，在获取rsp cache时，初始len需要从rsp cache中获取，发送部分报文后，根据已发送的长度推进更新
    hca_qpc.qpc_seg6.txwqe_rsp_retry_bk_data_sge_addr = '0;  // rsq retry发送时dif wqe断点，需要执行sge data在wqe内部的偏移，wqe断点sge块偏移地址，单位16Byte
    hca_qpc.qpc_seg6.txwqe_rsp_retry_bk_dif_sge_addr = '0;  // rsq retry发送时dif wqe断点，需要执行sge dif在wqe内部的偏移，wqe断点sge块偏移地址，单位16Byte
    hca_qpc.qpc_seg6.txwqe_rsp_retry_bk_block = '0;  // rsq retry发送时dif wqe断点，上一次pmtu插入dif后剩余block大小
    hca_qpc.qpc_seg6.txwqe_rsp_retry_phase_tag = '0;  // Veroce 下 response 长超时引发的重传指示，和sq 侧的phase 行为相同，在和rxt 的phase tag 不相同时代表有长超时重传
    hca_qpc.qpc_seg6.txwqe_req_sack_send_cnt = '0;  // Veroce 下 T端sack cnt，和rxt 的sack cnt不相等时有可能会有sack的发送，在ack eng处理结束后刷新成为rxt一样的值
    hca_qpc.qpc_seg6.txwqe_rsp_retry_bk_data_sge_ofs = '0;  // rsq重传发送时dif wqe断点，需要执行的data在sge内的偏移
    hca_qpc.qpc_seg6.txwqe_rsp_retry_bk_dif_sge_ofs = '0;  // rsq重传发送时dif wqe断点，需要执行的dif在sge内的偏移； Veroce 下为timestamp，us为单位；
    hca_qpc.qpc_seg6.txwqe_rsp_ack_psn = '0;  // veroce下，I端ack响应的psn号
    hca_qpc.qpc_seg6.txwqe_rsp_sack_send_retry_cnt = '0;  // veroce下I端在同一个PSN点回复sack的次数，每次刷新txwqe_rsp_ack_psn就清0，当同一个psn的重传次数达到某一个值（txwqe内部寄存器配置，默认8），就不再响应相同psn点的sack

    // ── seg 07 ──
    hca_qpc.qpc_seg7.long_bitmap = '0;  // 用于记录TX注册的normal超时信息的bitmap或者veroce send、write注册的长超时信息
    hca_qpc.qpc_seg7.short_bitmap = '0;  // 用于记录RX注册的短超时信息的bitmap或者Veroce txeng注册的ack的短超时bitmap
    hca_qpc.qpc_seg7.short_resp_bitmap = '0;  // 用于记录Veroce txeng注册的resp的短超时bitmap
    hca_qpc.qpc_seg7.long_read_req_bitmap = '0;  // 用于Veroce txeng注册的read req的长超时bitmap
    hca_qpc.qpc_seg7.long_read_resp_bitmap = '0;  // 用于记录Veroce txeng注册的read resp的长超时bitmap

    // ── seg 08 ──
    hca_qpc.qpc_seg8.txeng_qpc_rtr2rts_flag = '0;  // TX_ENG完成psn初始化标志位，具体初始化流程：收到txwqe首个SQ请求时决定是否要初始化tx_newest_unack_psn和tx_oldst_unack_psn标志位，0代表要初始化，初始化后置1，QP被初始化时被重置为0
    hca_qpc.qpc_seg8.txeng_hw_sqd2rts_phase_tag = '0;  // TX_ENG收到txwqe的SQD2RTS请求时，同步该标志位为qp_rc_sqd2rts_flag
    hca_qpc.qpc_seg8.txeng_resp_diff_err_flag = '0;  // TX_ENG在处理顺序发送的resp first/middle报文出现dif错误时置位，在处理顺序发送的resp last报文时清零
    hca_qpc.qpc_seg8.txeng_hw_rts2sqd_phase_tag = '0;  // RC QP且支持切SQD时有效： 当QP的请求出现dif校验异常时，将该标志位取反；
    hca_qpc.qpc_seg8.txeng_hw_sqer2rts_phase_tag = '0;  // UD/QP1请求时有效： TX_ENG收到txwqe的SQEr2RTS请求时，同步该标志位为qp_ud_sqer2rts_flag
    hca_qpc.qpc_seg8.txeng_sq_start_flag = '0;  // TX_ENG在成功处理首个SQ 报文之后置为1，用于区分npsn是否可给rx判断收应答包
    hca_qpc.qpc_seg8.txeng_qp_rst_destroy_flag = '0;  // 当前qp完成复位或者销毁操作的标志，用于dfx
    hca_qpc.qpc_seg8.txeng_sq_diff_err_flag = '0;  // TX_ENG在处理非重传的sq wr first/middle报文出现dif错误时置位，在处理非重传的wr last报文时清零
    hca_qpc.qpc_seg8.txeng_flush_flag = '0;  // QP 上送过FLUSH CQE标识（不包括sigerr cqe）
    hca_qpc.qpc_seg8.txeng_qp_state = 4'h3;  // QP的状态： 4'h3：RTS； 4'h5：SQEr； 4'h6：Error； 4'h7：SQ Draining； other：不支持
    hca_qpc.qpc_seg8.txeng_sq_err_flag = '0;  // QP首次置err的异常原因为SQ请求异常的标志
    hca_qpc.qpc_seg8.txeng_resp_err_flag = '0;  // QP首次置err的异常原因为RESP请求异常的标志
    hca_qpc.qpc_seg8.txeng_ok_req_ssn = '0;  // SQ请求包首次出错的ssn - 1
    hca_qpc.qpc_seg8.txeng_sq_err_syndrom = '0;  // TX_ENG在发送请求包时首次发送错误的类型，高2bit区分异常类型： 若为2'd1，则低6bit=txwqe err type; 若为2'd2，则低6bit则为txeng校验的dma/dif异常；
    hca_qpc.qpc_seg8.txeng_sq_err_wqe_idx = '0;  // TX_ENG在处理SQ请求发生错误时，需要调度重传的WQE wrid
    hca_qpc.qpc_seg8.txeng_qp_err_psn_l = '0;  // TX_ENG在处理SQ/RESP请求发生错误时，记录的该请求携带的起始psn低16位
    hca_qpc.qpc_seg8.txeng_qp_err_psn_h = '0;  // TX_ENG在处理SQ/RESP请求发生错误时，记录的该请求携带的起始psn高16位
    hca_qpc.qpc_seg8.txeng_npsn = sw.send_start_psn;  // TX_ENG计算的下一个请求包的PSN，仅在SQ请求时更新，重传时会回退，
    hca_qpc.qpc_seg8.txeng_send_req_next_ssn_l = '0;  // TX_ENG计算的下一个WQE的SSN低8位，仅在SQ请求时更新，重传时会回退
    hca_qpc.qpc_seg8.txeng_send_req_next_ssn_h = '0;  // TX_ENG计算的下一个WQE的SSN低8位，仅在SQ请求时更新，重传时会回退
    hca_qpc.qpc_seg8.txeng_tx2rx_retry_end_psn_l = '0;  // TX_ENG在发送重传请求时，记录txeng_tx2rx_retry_end_psn=txeng_newest_unack_psn，为txeng_tx2rx_retry_end_psn低16位
    hca_qpc.qpc_seg8.txeng_tx2rx_retry_end_psn_h = '0;  // TX_ENG在发送重传请求时，记录txeng_tx2rx_retry_end_psn=txeng_newest_unack_psn，为txeng_tx2rx_retry_end_psn高8位
    hca_qpc.qpc_seg8.txeng_syn_sch2rxi_retry_phase_tag = '0;  // 判断是否有报文发送到SDB（网络），有真实报文发送才同步TXWQE传递的FLAG  其余场景保持原QPC值
    hca_qpc.qpc_seg8.txeng_tx2rx_retry_flag = '0;  // 1.TX_ENG在重传SQ REQ时拉起该标志， 2.在执行非重传SQ请求时，当txeng_tx2rx_retry_flag为1并且TX_ENG判断到rxi_newset_ack_psn >= txeng_tx2rx_retry_end_psn时拉低该标志，表示重传的请求已经全部被RX应答了。SQ、RESP请求时更新。
    hca_qpc.qpc_seg8.txeng_ssnt_wr_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // 当前QP的ssnt wr指针，QP为RC/DCI时有效；
    hca_qpc.qpc_seg8.txeng_irrl_wr_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // 当前QP的irrl wr指针，QP为RC/DCI时有效；
    hca_qpc.qpc_seg8.txeng_read_bitmap_l = '0;  // 在QP开启自研ooo选择性重传时有效，维护TX发出的RDMA请求的bitmap 低128位。采用业务报文的psn低8位作为索引，对bitmap做清0置位操作：置位条件是发read、atomic报文，其他业务报文(不包含cnp)都是清零
    hca_qpc.qpc_seg8.txeng_read_bitmap_h = '0;  // 在QP开启自研ooo选择性重传时有效，维护TX发出的RDMA请求的bitmap 高128位。采用业务报文的psn低8位作为索引，对bitmap做清0置位操作：置位条件是发read、atomic报文，其他业务报文(不包含cnp)都是清零
    hca_qpc.qpc_seg8.txeng_sack_retry_cnt = '0;  // 在QP开启veroce ooo选择性重传时有效，直接同步txwqe传递qpc index有效请求时ctrl info里的sack_retry_cnt
    hca_qpc.qpc_seg8.txeng_sack_rsp_retry_cnt = '0;  // 在QP开启veroce ooo选择性重传时有效，直接同步txwqe传递qpc index有效请求时ctrl info里的sack_rsp_retry_cnt
    hca_qpc.qpc_seg8.txeng_newest_ack_req_psn_l = '0  // init: sw.send_start_psn-1;  // 最新置位ACK_REQ的请求包PSN低16位，仅在RC SQ请求时更新，重传时不回退
    hca_qpc.qpc_seg8.txeng_newest_ack_req_psn_h = '0  // init: sw.send_start_psn-1;  // 最新置位ACK_REQ的请求包PSN低16位，仅在RC SQ请求时更新，重传时不回退
    hca_qpc.qpc_seg8.txeng_newest_unack_psn = '0;  // 最新未应答的PSN，仅在RC SQ请求时更新
    hca_qpc.qpc_seg8.txeng_tmo_stamp_h = '0;  // TX_ENG最新记录的超时时间戳us及以上部分，单位1us，重传时回退
    hca_qpc.qpc_seg8.txeng_oldest_unack_psn = '0;  // 最旧未应答的PSN，仅在RC SQ、RESP请求时更新
    hca_qpc.qpc_seg8.txeng_tmo_log_rtm = '0;  // 超时退避倍数 = 2^txeng_tmo_log_rtm，实际取值范围0~8。仅在RC SQ、RESP请求时更新 step1.判断有请求被应答时，该值取0。 step2.接着step1判断，当开启超时退避且当前为nak/tmo重传首个请求时，进行计算：nak_cnt+qpc.log_rtm-1。
    hca_qpc.qpc_seg8.txeng_sync_rd_rsp_retry_phase_tag = '0;  // 在QP开启veroce ooo选择性重传时有效，当txwqe传递qpc index有效的read rsp/atomic ack请求时，直接同步ctrl info里的sch2rxi_rd_rsp_retry_phase_tag
    hca_qpc.qpc_seg8.txeng_txe2cc_bc_syn_flag = '0;  // 与HWCC模块的bc_clr_flag不一致时，须清零txeng_cc_record_byte_length，并同步该标志为HWCC模块的bc_clr_flag
    hca_qpc.qpc_seg8.txeng_cc_record_byte_length = '0;  // txeng统计的已发送报文字节数（单位：Byte），当反馈升速请求给拥塞模块后，该值须减去寄存器配置的升速阈值。
    hca_qpc.qpc_seg8.txeng_rtt_stamp_h = '0;  // TX_ENG发送打bth_a的报文，且rtt_phase_flag相等时，记录系统时间，单位1us
    hca_qpc.qpc_seg8.txeng_rtt_psn = '0;  // TX_ENG发送打bth_a的报文，且rtt_phase_flag相等时，记录报文psn
    hca_qpc.qpc_seg8.txeng_rtt_phase_flag = '0;  // TX_ENG发送打bth_a的报文，且rtt_phase_flag相等时，翻转该标志位
    hca_qpc.qpc_seg8.txeng_newest_cqe_wrid_vld_flag = '0;  // TXENG最新上报的cqe对应wrid有效标志，用于dfx
    hca_qpc.qpc_seg8.txeng_newest_cqe_wrid = '0;  // TXENG最新上报的cqe对应的wrid，用于dfx
    hca_qpc.qpc_seg8.txeng_ctrl_info_cnt = '0;  // txeng每处理一个qp index有效的ctrl info则++，计满翻转

    // ── seg 09 ──
    hca_qpc.qpc_seg9.rxi_upsn = '0  // init: send_start_psn;  // rxi最老未应答psn；乱序接收和选择性重传时，代表未应答窗口的左边界
    hca_qpc.qpc_seg9.rxi_upsn_synced = '0;  // 首次检测到软件qp_state=RTS时，用send_start_psn同步upsn后置1
    hca_qpc.qpc_seg9.rxi_irrl_sge_va = '0;  // irrl断点irrl_sge_va
    hca_qpc.qpc_seg9.rxi_irrl_sge_lkey = '0;  // irrl断点irrl_sge_lkey
    hca_qpc.qpc_seg9.rxi_irrl_sge_length = '0;  // irrl断点irrl_sge_length
    hca_qpc.qpc_seg9.rxi_irrl_sqe_psn = '0;  // irrl断点irrl_sqe_spsn
    hca_qpc.qpc_seg9.rxi_irrl_psn_vld = '0;  // irrl断点psn有效
    hca_qpc.qpc_seg9.rxi_irrl_sqe_opcode = '0;  // irrl断点irrl_sqe_opcode[4:0]
    hca_qpc.qpc_seg9.rxi_irrl_sge_last = '0;  // irrl断点irrl_sge_last
    hca_qpc.qpc_seg9.rxi_irrl_bp_vld = '0;  // irrl断点有效
    hca_qpc.qpc_seg9.rxi_byte_count = '0;  // 记录已收响应包的长度，rxi端用于记录RDMA_R应答包的数据长度
    hca_qpc.qpc_seg9.rxi_retry_flag = '0;  // rxi端收到了应答包校验需要重传时，设置成~tx_eng_retry_flag
    hca_qpc.qpc_seg9.rxi_read_atomic_retry_flag = '0;  // I端需要重传read/atomic拉高此信号，只接收psn=upsn的应答包
    hca_qpc.qpc_seg9.rxi_opcode_resp = 5'h11;  // 用于记录rxi端接收响应包的opcode[4:0]
    hca_qpc.qpc_seg9.rxi_fake_err_flag = '0;  // 是否收到置错命令标记
    hca_qpc.qpc_seg9.rxi_fake_rst_flag = '0;  // 是否收到reset命令标记
    hca_qpc.qpc_seg9.rxi_fake_des_flag = '0;  // 是否收到销毁命令标记
    hca_qpc.qpc_seg9.rxi_irrl_prefetch_ptr = '0;  // irrl预取指针
    hca_qpc.qpc_seg9.rxi_irrl_rd_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // irrl读指针
    hca_qpc.qpc_seg9.rxi_chk_err_flag = '0;  // 是否有校验出致命错误标记
    hca_qpc.qpc_seg9.rxi_swcc_time_vld = '0;  // rxi_swcc_time有效标识
    hca_qpc.qpc_seg9.rxi_resp_bitmap = '0;  // 乱序接收和选择性重传时使用，维护rxi收到的read_resp/atomic_ack报文情况，在收到read_resp/atomic_ack报文的时候更新 veRoCE复用：接收read_resp/ato_ack的bitmap，veRoCE的qp在RTS时会由RXI自己初始化为send_start_psn[8] ? ({256{1'b1}} << send_start_psn[7:0])： ~ ({256{1'b1}} << send_start_psn[7:0])
    hca_qpc.qpc_seg9.rxi_irrl_sqe_wrid = '0;  // irrl断点irrl_sqe_wrid
    hca_qpc.qpc_seg9.rxi_swcc_time = '0;  // RoCE/veRoCE场景下，ECN为10时上报SWCC事件的时间戳，单位ms
    hca_qpc.qpc_seg9.rxi_tgt_left_psn = '0;  // 乱序接收和选择性重传时使用，维护收到应答里携带的tgt收请求的左边界 veRoCE复用：接收read_resp/ato_ack的左边界rxi_rsp_left_psn，veRoCE的qp在RTS时会由RXI自己初始化为send_start_psn
    hca_qpc.qpc_seg9.rxi_tgt_hole_num = '0;  // 乱序接收和选择性重传时使用，维护收到应答里携带的tgt空洞的大小
    hca_qpc.qpc_seg9.rxi_mrc_dif_pa = '0;  // 间接klm模式下存放第一个klm的pa（klm存放为先dif后data） mtt模式下存放第一个pbl的pa（pbl存放为先dif后data） 直接klm模式下不使用 veRoCE复用[23:0]：接收read_resp/ato_ack的右边界rxi_rsp_max_right_psn，veRoCE的qp在RTS时会由RXI自己初始化为send_start_psn-1
    hca_qpc.qpc_seg9.rxi_mrc_data_pa_num = '0;  // 间接klm模式下存放mrc中data_klm_num mtt模式下存放mrc中data_pbl_num 直接klm模式下不使用
    hca_qpc.qpc_seg9.rxi_mrc_dif_pa_num = '0;  // 间接klm模式下存放mrc中data_klm_num mtt模式下存放mrc中data_pbl_num 直接klm模式下不使用
    hca_qpc.qpc_seg9.rxi_mrc_data_pa_num_bp = '0;  // 间接klm模式下使用到的data_klm_num mtt模式下使用到的data_pbl_num 直接klm模式下不使用
    hca_qpc.qpc_seg9.rxi_mrc_dif_pa_num_bp = '0;  // 间接klm模式下使用到的data_klm_num mtt模式下使用到的data_pbl_num 直接klm模式下不使用
    hca_qpc.qpc_seg9.rxi_mrc_bp_vld = '0;  // mrc断点有效
    hca_qpc.qpc_seg9.rxi_mrc_log_page_size = '0;  // mtt模式下存放mtt_mrc中读出的log_page_size
    hca_qpc.qpc_seg9.rxi_mrc_w_dif_block_size = '0;  // 存放mrc中读出的w_dif_block_size
    hca_qpc.qpc_seg9.rxi_mrc_m_dif_block_size = '0;  // 存放mrc中读出的m_dif_block_size
    hca_qpc.qpc_seg9.rxi_mrc_ro_wr = '0;  // 存放mrc中读出的relaxed_ordering_write，用QPC中的relaxed_ordering_sel选择后，给DMA使用
    hca_qpc.qpc_seg9.rxi_mrc_ro_rd = '0;  // 存放mrc中读出的relaxed_ordering_read，用QPC中的relaxed_ordering_sel选择后，给DMA使用
    hca_qpc.qpc_seg9.rxi_mrc_dif_sge_mode = '0;  // 存放mrc中读出的dif_sge_mode DIF模式下的数据关联模式 0：MTT模式：此时MRC中携带Data和DIF的PBL起始PA 1：直接KLM模式，DIF和DATA均只有1个KLM，在当前MRC中直接存放data_klm和dif_klm，如果access_mode为PA模式，则klm中为数据和DIF的物理地址；如果access_mode为VA模式，则klm中为数据和DIF的虚拟地址，因此需要做VA2PA转换 2：间接KLM模式，当前MRC中存放主机内存中data_klm和dif_klm的起始物理地址，如果access_mode为PA模式，则KLM中填写的地址为物理地址；如果access_mode为VA模式，则KLM中填写的地址为虚拟地址，需要做VA2PA转换 其它：reserved
    hca_qpc.qpc_seg9.rxi_mrc_access_mode = '0;  // 存放mrc信息：访问模式： 0x0: PA模式 0x1: VA模式
    hca_qpc.qpc_seg9.rxi_mrc_dif_list_type = '0;  // 存放mrc信息：散列表类型： 0：单散列表，DIF_metadata与DATA交错存放在指定的内存中 1：双散列表，DIF_metadata与DATA分开存放。
    hca_qpc.qpc_seg9.rxi_block_offset = '0;  // 上一包在DIF BLOCK内的偏移，用于计算当前包内的DIF长度
    hca_qpc.qpc_seg9.rxi_mrc_dif_flag = '0;  // 存放mrc信息：是否为dif的mrc 0：普通MRC 1：DIF MRC
    hca_qpc.qpc_seg9.rxi_sack_rsp_th_flag = '0;  // veRoCE新增：接收read_resp/ato_ack乱序程度超过阈值，触发sack_rsp门铃时拉高，rxi_tgt_left_psn超过rxi_sack_right_psn时拉低
    hca_qpc.qpc_seg9.rxi_mrc_dif_key = '0;  // 直接klm模式下mrc中data sge的key； 间接klm模式下从pa中读出的data sge的key； mtt模式下不使用
    hca_qpc.qpc_seg9.rxi_mrc_dif_len = '0;  // 直接klm模式下mrc中data sge的len断点 间接klm模式下从pa中读出的data sge的len断点； mtt模式下为pbl页的剩余长度断点 为0时代表断点无效
    hca_qpc.qpc_seg9.rxi_mrc_dif_addr = '0;  // 直接klm模式下mrc中data sge的地址断点； 间接klm模式下从pa中读出的data sge的addr断点； mtt模式下从pa中读出的pbl页的地址断点
    hca_qpc.qpc_seg9.rxi_mrc_data_key = '0;  // 直接klm模式下mrc中data sge的key； 间接klm模式下从pa中读出的data sge的key； mtt模式下不使用
    hca_qpc.qpc_seg9.rxi_mrc_data_len = '0;  // 直接klm模式下mrc中data sge的len断点 间接klm模式下从pa中读出的data sge的len断点； mtt模式下为pbl页的剩余长度断点 为0时代表断点无效 veRoCE复用[23:0]：rxi_sack_right_psn，接收read_resp/ato_ack乱序程度超过阈值或收到S_TMO，触发sack_rsp门铃时记录，rxi_rsp_right_psn-TH。没触发sack_rsp时同步为rxi_tgt_left_psn-1
    hca_qpc.qpc_seg9.rxi_mrc_data_addr = '0;  // 直接klm模式下mrc中data sge的地址断点； 间接klm模式下从pa中读出的data sge的addr断点； mtt模式下从pa中读出的pbl页的地址断点
    hca_qpc.qpc_seg9.rxi_chk_err_psn = '0;  // 校验出致命错误包的psn，乱序模式下记录，只处理这个psn之前的包，这个psn后的包会被丢弃
    hca_qpc.qpc_seg9.rxi_sack_send_cnt = '0;  // veRoCE新增：接收read_resp/ato_ack乱序程度超过阈值或收到S_TMO，触发sack_rsp门铃时cnt++

    // ── seg 10 ──
    hca_qpc.qpc_seg10.rxi_complete_wqe_wrid = '0;  // DFX，记录已经完成的WQE wrid信息；
    hca_qpc.qpc_seg10.rxi_complete_wqe_ce = '0;  // DFX，记录已经完成的WQE CE信息；
    hca_qpc.qpc_seg10.rxi_complete_wqe_ds = '0;  // DFX，记录已经完成WQE DS(64B为单位)信息；
    hca_qpc.qpc_seg10.rxi_err_cqe_syndrome = '0;  // 记录rxi置错qp的cqe 类型
    hca_qpc.qpc_seg10.rxi_qp_state = 4'h3;  // RX I端的qp_state： 4'h3：RTS； 4'h4：SQD； 4'h6：Error； other：unkown。 RX I端在RTS收应答包；并在校验error刷新状态为Error；
    hca_qpc.qpc_seg10.rxi_resp_msn = hca_qpc.start_ssn-1;  // 收到正确应答的msn，用于TX_WQE模块计算lsn
    hca_qpc.qpc_seg10.rxi_credit = '0;  // 收到正确应答的credit，用于TX_WQE模块计算lsn
    hca_qpc.qpc_seg10.rxi_qp_state_err_flag = '0;  // qp置错时，收到对应fake_ack会将其置1，并按门铃表示此次重传需要快速flush sqe
    hca_qpc.qpc_seg10.rxi_reset_flag = '0;  // 收到软件下发了QP Reset命令的fake_ack后拉高此flag
    hca_qpc.qpc_seg10.rxi_destroy_flag = '0;  // 收到软件下发了QP Destroy命令的fake_ack后拉高此flag
    hca_qpc.qpc_seg10.rxi_ack_time_stamp = '0;  // 用于记录确认ACK的时间戳，单位为us(sys_timer[41:10])，在RNR重传时作为TX起点计时
    hca_qpc.qpc_seg10.rxi_unack_wqe_ssn = hca_qpc.start_ssn;  // 记录从ssnt中读出的未应答的sqe.ssn，用于重传时通知TX需要重传的SSN； sqd2rts 时 txwqe 会同步该ssn veRoCE复用：记录从ssnt中读出的未应答的rxi_unack_wqe_resp_psn
    hca_qpc.qpc_seg10.rxi_unack_wqe_opcode = '0;  // 用于记录从ssnt中读出的未应答的sqe.opcode
    hca_qpc.qpc_seg10.rxi_unack_wqe_length = '0;  // 用于记录从ssnt中读出来的未应答的sqe.length
    hca_qpc.qpc_seg10.rxi_unack_wqe_start_psn = '0  // init: send_start_psn;  // 用于记录每次最开始未确认的WQE的start_psn，用于重传时通知TX需要重传的起点，可以计算go back to 0/n
    hca_qpc.qpc_seg10.rxi_unack_wqe_ce = '0;  // 记录从ssnt中读出的未应答的sqe.ce
    hca_qpc.qpc_seg10.rxi_unack_wqe_ds = '0;  // 记录从ssnt中读出的未应答的sqe.ds(64B为单位)
    hca_qpc.qpc_seg10.rxi_unack_wqe_wrid = '0;  // 用于记录每次最开始未确认的sqe的wrid；sqd2rts 时 txwqe 会同步该wrid
    hca_qpc.qpc_seg10.rxi_unack_wqe_irrl_ptr = '0;  // 记录重传时从ssnt读出来的irrl_wr_ptr信息；sqd2rts 时 txwqe 会同步该irrl ptr
    hca_qpc.qpc_seg10.rxi_ssnt_bp_vld = '0;  // 表示从ssnt读出来的未应答信息是否有效。0无效，1有效
    hca_qpc.qpc_seg10.rxi_rnr_retry_flag = '0;  // I端收到RNR NAK时需要设置为1，TX可以根据此位识别RNR重传
    hca_qpc.qpc_seg10.rxi_resp_rnr_nak_tmr = '0;  // I端收到RNR NAK时需要填入rnr_time，当rxi_rnr_retry_flag=1时表示重传为RNR重传
    hca_qpc.qpc_seg10.rxi_sq_oldest_unack_psn = '0  // init: send_start_psn;  // rxi最旧未应答的psn；sqd2rts 时 txwqe 会同步该irrl ptr
    hca_qpc.qpc_seg10.rxi_retry_phase_flag = '0;  // rxi端重传标记，同步成rxi_retry_flag，通知TX有重传
    hca_qpc.qpc_seg10.rxi_retrying_flag = '0;  // rxi端发起sq重传后置1，当收到校验通过的应答psn达到tx_retry_end_psn后置0。供ack_timeout_proc模块判断是否要触发超时重传
    hca_qpc.qpc_seg10.rxi_dc_conn_flag = '0;  // rxi端发起重传时，需要重传建链包将其置1
    hca_qpc.qpc_seg10.rxi_sr_tmo_vld = '0;  // 乱序接收和选择性重传使用，rxi记录是否注册过短超时
    hca_qpc.qpc_seg10.rxi_rtt_phase_flag = '0;  // rxi接收应答，如果不等于tx_rtt_phase_flag且应答psn>=tx_rtt_psn，翻转rxi_rtt_phase_flag，并计算RTT记录
    hca_qpc.qpc_seg10.rxi_sq_oldest_upsn_synced = '0;  // 首次检测到软件qp_state=RTS时，用send_start_psn同步rxi_sq_oldest_unack_psn和rxi_unack_wqe_start_psn后置1
    hca_qpc.qpc_seg10.rxi_cnp_db_time_vld = '0;  // rxi_cnp_db_time是否有效的标识。第一次上送完cnp门铃后置1。后续就可以使用rxi_cnp_db_time来过滤
    hca_qpc.qpc_seg10.rxi_cnp_db_time = '0;  // 上次按CNP门铃的时间戳，此时间+cnp_send_gap内收到ECN不再按CNP门铃
    hca_qpc.qpc_seg10.rxi_ssnt_prefetch_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // ssnt预取指针
    hca_qpc.qpc_seg10.rxi_ssnt_rd_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // ssnt读指针
    hca_qpc.qpc_seg10.rxi_amsn_pass_ssnt_flag = '0;  // veRoCE新增：rxi_resp_msn应答超过txeng_ssnt_wr_ptr后置1，TXWQE收到重传门铃时，如果看到该flag为1则不发起重传，仅同步retry_phase_flag/retry_cnt
    hca_qpc.qpc_seg10.rxi_path_index = '0;  // veRoCE新增：响应包中的sport对应路径，用于TX调度ack/sack/cnp/rtt时选择对应的path_id
    hca_qpc.qpc_seg10.rxi_local_wqe_phase_flag = '0;  // veRoCE新增：和TXWQE极性不相等时判断要上报local wqe的cqe。上报完后，会将该phase_flag同步为TXWQE一致
    hca_qpc.qpc_seg10.rxi_rsp_ack_retry_phase_flag = '0;  // veRoCE新增：如果收到重传的read_resp/ato_ack需要回复ack_rsp，会将这个翻转成和TXWQE不一致
    hca_qpc.qpc_seg10.rxi_unack_wqe_resp_obit = '0;  // 乱序接收和选择性重传时使用，rxi端记录从ssnt中读出的resp_obit
    hca_qpc.qpc_seg10.rxi_unack_wqe_resp_ptr = '0;  // 乱序接收和选择性重传时使用，rxi端记录从ssnt中读出的resp_ptr veRoCE复用[7:6]：为rxi_remote_sport_rr_ptr，用于RXT sport无法匹配时，RR替换对应的entry veRoCE复用[5:0]：为rxi_remote_sport_l_3，远端路径四 UDP source port 低6bit （用于veRoCE多路径返回CNP 和ACK）
    hca_qpc.qpc_seg10.rxi_retrans_left_psn = '0;  // 乱序接收和选择性重传时使用，rxi端维护重传请求空洞的左边界 veRoCE复用：接收read_resp/ato_ack后TXWQE回ack_rsp的最新rxi_rsp_ack_newest_psn，veRoCE的qp在RTS时会由RXI自己初始化为send_start_psn-1
    hca_qpc.qpc_seg10.rxi_retrans_hole_num = '0;  // 乱序接收和选择性重传时使用，rxi端维护重传请求空洞的大小 veRoCE复用[5:0]：为rxi_remote_sport_l_2，远端路径三 UDP source port 低6bit （用于veRoCE多路径返回CNP 和ACK）
    hca_qpc.qpc_seg10.rxi_sr_time = veroce_en ? hca_qpc.start_ssn-1 : '0;  // 乱序接收和选择性重传时使用，rxi记录短超时时间 veRoCE复用[29:24]：为rxi_remote_sport_l_1，远端路径二 UDP source port 低6bit （用于veRoCE多路径返回CNP 和ACK） veRoCE复用[23:0]：每应答一个read/atomic请求就加1，用于TXWQE回复ack_rsp填到AETH.MSN的最新rxi_rsp_ack_msn
    hca_qpc.qpc_seg10.rxi_err_wrid = '0;  // 收到致命nak（包括fake_nak）或vapa校验错误，但是前面有未完成请求时，先记录出错的wrid，等待前面未完成的响应。此域段在rxi_err_type不为0时有效。如果rxi_err_type已记录，但新的错误psn早于此字段记录的值，则更新此字段为新错误的err_wrid
    hca_qpc.qpc_seg10.rxi_dci_err_phase_flag = '0;  // 当qp_type=DCI时，如果rxi_err_type不为0，且未应答点到达rxi_err_wrid时，翻转该flag，通知tx从unack_wrid点开始flush同目的DCT的sqe
    hca_qpc.qpc_seg10.rxi_dci_err_vld = '0;  // 当qp_type=DCI时，识别到错误记录rxi_err_wrid和rxi_err_type时置1.等到未应答点达到rxi_err_wrid，翻转rxi_dci_err_phase_flag时清0。用于在等应答时通知txwqe在rxi_err_wrid后的wqe不能发送
    hca_qpc.qpc_seg10.rxi_rtt_time = '0;  // DFX，记录rtt时间，单位为us。rtt超过位宽时记为31
    hca_qpc.qpc_seg10.rxi_err_source = '0;  // 记录rxi_err_type置错时的错误来源，0代表rxi错，1代表tx fake错
    hca_qpc.qpc_seg10.rxi_err_type = '0;  // 收到致命nak（包括fake_nak）或vapa校验错误，但是前面有未完成请求时，先记录出错的类型在该域段。如果该字段已记录，但新的错误wrid早于rxi_err_wrid记录的值，则更新此字段为新错误的err_type。 对于RC qp，等到所有前面未完成的完成后（left_psn达到此rxi_err_psn或rxi_err_wrid），才可置错qp和记录rxi_err_cqe_syndrome。 对于DCI qp，不置错qp，但是翻转rxi_dci_err_phase_flag
    hca_qpc.qpc_seg10.rxi_hw_rts2sqd_phase_flag = '0;  // 当rxi收到fake_rts2sqd时，如果未应答wrid=fake内的wrid，则翻转此flag并上报SQD异步事件并将rxi_qp_state改为SQD状态或 当收到响应包时，若rxi_hw_sqd_vld为1，且未应答wrid=rxi_hw_sqd_wrid，则翻转此flag并上报异步事件并将rxi_qp_state改为SQD状态
    hca_qpc.qpc_seg10.rxi_hw_sqd_vld = '0;  // rxi收到fake_rts2sqd时，如果未应答wrid != fake内的wrid，则将此flag置1。等到未应答点到达rxi_hw_sqd_wrid时清0
    hca_qpc.qpc_seg10.rxi_dif_err_cqe_record = '0;  // rxi一个message上送过dif校验错误cqe的记录
    hca_qpc.qpc_seg10.rxi_hw_sqd2rts_phase_flag = '0;  // 当收到tx的FAKE_ACK_RTS时，表示要切RTS。将此字段同步为seg3.qp_rc_sqd2rts_phase_flag，并将rxi_qp_state改为RTS状态
    hca_qpc.qpc_seg10.rxi_err_cqe_minor_syndrome = '0;  // 记录rxi置错qp的cqe minor类型
    hca_qpc.qpc_seg10.rxi_hw_sqd_wrid = '0;  // rxi收到fake_rts2sqd时，如果未应答wrid != fake内的wrid，则将fake内的wrid记录在此 veRoCE复用[15:6]：为rxi_remote_sport_h，远端UDP source port 高10bit（用于veRoCE多路径返回CNP 和ACK） veRoCE复用[5:0]：为rxi_remote_sport_l_0，远端路径一 UDP source port 低6bit （用于veRoCE多路径返回CNP 和ACK）
    hca_qpc.qpc_seg10.rxi_dif_data = '0;  // rxi暂存message的dif校验数据中间结果 veRoCE复用[159:152]：收到sack后，通知TXWQE进行选择性重传的rxi_req_sack_retry_cnt，每次触发新选择性重传时++ veRoCE复用[135:128]：收到sack后，通知TXWQE进行选择性重传的长度rxi_req_sack_len veRoCE复用[127:0]：收到sack后，通知TXWQE进行选择性重传的rxi_req_sack_bitmap
    hca_qpc.qpc_seg10.rxi_complete_irrl_next_wqe_start_ptr = '0;  // 记录已完成WQE的irrl_next_wqe_start_ptr，从SSNT中读出 在乱序接收和选择性重传时，供TXWQE识别IRRL的剩余空间 veRoCE复用：记录最后一笔已完成WQE的SSNT.irrl_wr_ptr，供TXWQE识别IRRL的剩余空间
    hca_qpc.qpc_seg10.rxi_unack_irrl_next_wqe_start_ptr = '0;  // 记录从ssnt中读出的未应答WQE的irrl_next_wqe_start_ptr
    hca_qpc.qpc_seg10.rxi_cnp_path_bitmap = '0;  // 记录当前GAP内，对应path是否已调度CNP，避免多次门铃
    hca_qpc.qpc_seg10.rxi_cnp_phase_flag = '0;  // [3:0]对应PATH3~PATH0，对应PATH需要调度CNP包时，对应bit翻转为~txwqe_txi_cnp_phase_tag[]
    hca_qpc.qpc_seg10.rxi_cnp_cc_time_vld = '0;  // rxi_cnp_cc_time是否有效的标识。第一次上送完cnp事件后置1。后续就可以使用rxi_cnp_cc_time来过滤
    hca_qpc.qpc_seg10.rxi_cnp_cc_time = '0;  // 上次上送CNP时间的时间戳，此时间+cnp_cc_event_gap内收到CNP不再上送CNP CC事件
    hca_qpc.qpc_seg10.rxi_err_psn = '0;  // 收到致命nak（包括fake_nak）或vapa校验错误，但是前面有未完成请求时，先记录出错的psn，等待前面未完成的响应。此域段在rxi_err_type不为0时有效。如果rxi_err_type已记录，但新的错误psn早于此字段记录的值，则更新此字段为新错误的err_psn
    hca_qpc.qpc_seg10.rxi_err_minor_type = '0;  // 收到致命nak（包括fake_nak）或vapa校验错误，但是前面有未完成请求时，先记录出错的minor类型在该域段。如果该字段已记录，但新的错误wrid早于rxi_err_wrid记录的值，则更新此字段为新错误的err_minor_type。 对于RC qp，等到所有前面未完成的完成后（left_psn达到此rxi_err_psn或rxi_err_wrid），才可置错qp和记录rxi_err_cqe_minor_syndrome。

    // ── seg 11 ──
    hca_qpc.qpc_seg11.rxt_sge_va = '0;  // RDMA_W/SEND_sge的断点 DIF KLM模式下data_sge的断点 DIF MTT模式下data_pbl的断点 veRoCE场景：hw_counter的这笔RQE中第一笔sge的sge_va
    hca_qpc.qpc_seg11.rxt_sge_key = '0;  // RDMA_W/SEND_sge的断点 DIF KLM模式下data_sge的断点 DIF MTT模式下rsv veRoCE场景：hw_counter的这笔RQE中第一笔sge的sge_key
    hca_qpc.qpc_seg11.rxt_sge_len = '0;  // RDMA_W/SEND_sge的断点 DIF KLM模式下data_sge的断点 DIF MTT模式下data_pbl的断点 veRoCE场景：hw_counter的这笔RQE中第一笔sge的sge_len
    hca_qpc.qpc_seg11.rxt_sge_num = '0;  // RQE断点sge_num
    hca_qpc.qpc_seg11.rxt_resp_cnt = '0;  // 收到read/atomic请求的指针
    hca_qpc.qpc_seg11.rxt_rnr_nak_flag = '0;  // 触发rnr nak，只能接收rxt_epsn的包 veRoCE场景：触发rnr_nak，后续只能接收left_psn及不消耗RQE/SRQE的包
    hca_qpc.qpc_seg11.rxt_psn_nak_flag = '0;  // 触发psn nak，只能接收rxt_epsn的包
    hca_qpc.qpc_seg11.rxt_hw_counter_pre = '0;  // 已预取RQE的指针
    hca_qpc.qpc_seg11.rxt_fake_write_flag = '0;  // 收到fake包
    hca_qpc.qpc_seg11.rxt_fake_rst_flag = '0;  // 收到fake_rst
    hca_qpc.qpc_seg11.rxt_fake_destroy_flag = '0;  // 收到fake_destroy
    hca_qpc.qpc_seg11.rxt_opcode_req = 5'h4;  // 用于记录T端接收请求包的opcode[4:0]
    hca_qpc.qpc_seg11.rxt_epsn = hca_qpc.qpc_seg00.rcv_start_psn;  // 非乱序接收模式时，表示预期收到包的PSN 乱序接收模式时，表示顺序收包的预期PSN，即上一个包的PSN+1，用于乱序收包DFX
    hca_qpc.qpc_seg11.rxt_byte_count = '0;  // T端记录当前已接收的多包请求包payload长度 veRoCE场景： [23:0]：复用为rxt_qp_err_psn，表示出现致命错误的最左侧psn； [31:24]：rsv
    hca_qpc.qpc_seg11.rxt_sw_counter = '0;  // 当前SW RQ WQE index, 指向HW将产生的下一个WQE，[31:16]位保留（仅限QUERY_QP）。 如果rq_type==srq或no_rq，则保留
    hca_qpc.qpc_seg11.rxt_hw_counter = '0;  // 当前HW RQ WQE index，指向HW将消耗的下一个WQE，[31:16]位保留（仅限QUERY_QP）。如果rq_type==srq或no_rq，则保留
    hca_qpc.qpc_seg11.rxt_page_pa = '0;  // rq_page_paddr
    hca_qpc.qpc_seg11.rxt_page_pa_vld = '0;  // page_pa有效
    hca_qpc.qpc_seg11.rxt_rtr_first_pkt = '0;  // RTR状态下收到第一个正确的请求包。
    hca_qpc.qpc_seg11.rxt_qp_err_flag = '0;  // RXT_PRE出现致命错误时拉高，过滤后续请求包 veRoCE场景：出现致命错误，后续只能接收qp_err_psn前面的包
    hca_qpc.qpc_seg11.rxt_left_psn = hca_qpc.qpc_seg00.rcv_start_psn;  // 乱序接收时，接收有效请求的左边界
    hca_qpc.qpc_seg11.rxt_right_psn = hca_qpc.qpc_seg00.rcv_start_psn-1;  // 乱序接收时，接收有效请求的右边界
    hca_qpc.qpc_seg11.rxt_req_bitmap = // TODO(manual): rcv_start_psn[8] ? ({256{1'b1}} << rcv_start_psn[7:0])： ~ ({256{1'b1}} << rcv_start_psn[7:0]);  // 乱序接收时，接收请求的bitmap
    hca_qpc.qpc_seg11.rxt_mrc_key = '0;  // 存放write首包携带的reth_key，DIF场景下使用 veRoCE场景： [9:0]：复用为rxt_page_num，表示当前page_pa对应的是RQ/SRQ的第几个页 [31:10]：rsv
    hca_qpc.qpc_seg11.rxt_mrc_ro_write = '0;  // 存放mrc信息：启用宽松排序写属性
    hca_qpc.qpc_seg11.rxt_mrc_ro_read = '0;  // 存放mrc信息：启用宽松排序读属性
    hca_qpc.qpc_seg11.rxt_block_offset = '0;  // 上一包在DIF BLOCK内的偏移，用于计算当前包内的DIF长度
    hca_qpc.qpc_seg11.rxt_mrc_info_vld = '0;  // mrc信息有效
    hca_qpc.qpc_seg11.rxt_mrc_access_mode = '0;  // 存放mrc信息：访问模式： 0x0: PA模式 0x1: VA模式
    hca_qpc.qpc_seg11.rxt_mrc_dif_list_type = '0;  // 存放mrc信息：散列表类型： 0：单散列表，DIF_metadata与DATA交错存放在指定的内存中 1：双散列表，DIF_metadata与DATA分开存放。
    hca_qpc.qpc_seg11.rxt_mrc_w_dif_block_size = '0;  // 存放mrc信息：网络侧的block大小： 0：512B 1：512+8B 2：4096B 3：4096+8B
    hca_qpc.qpc_seg11.rxt_mrc_m_dif_block_size = '0;  // 存放mrc信息：内存侧的block大小： 0：512B 1：512+8B 2：4096B 3：4096+8B
    hca_qpc.qpc_seg11.rxt_mrc_dif_sge_mode = '0;  // 存放mrc信息：DIF模式下的数据关联模式 0：MTT模式：此时MRC中携带Data和DIF的PBL起始PA 1：直接KLM模式，DIF和DATA均只有1个KLM，在当前MRC中直接存放data_klm和dif_klm，如果access_mode为PA模式，则klm中为数据和DIF的物理地址；如果access_mode为VA模式，则klm中为数据和DIF的虚拟地址，因此需要做VA2PA转换 2：间接KLM模式，当前MRC中存放主机内存中data_klm和dif_klm的起始物理地址，如果access_mode为PA模式，则KLM中填写的地址为物理地址；如果access_mode为VA模式，则KLM中填写的地址为虚拟地址，需要做VA2PA转换 其它：reserved
    hca_qpc.qpc_seg11.rxt_mrc_log_entity_size = '0;  // 存放mrc信息： 报文数据所在的物理页大小为2^log_entity_size，log_page_size的取值为12-30的整数，即支持的页面配置为4KB~1GB  在一级页表模式下固定为30，即页大小为1GB，二级三级页表模式下可配置为12~30
    hca_qpc.qpc_seg11.rxt_mrc_entry_pa = '0;  // 存放mrc信息： DIF 间接KLM模式下，第一个KLM的pa DIF MTT模式下，第一个pbl的pa
    hca_qpc.qpc_seg11.rxt_mrc_data_num = '0;  // 存放mrc信息： DIF 间接KLM模式下，data_klm的总数 DIF MTT模式下，data_pbl的总数
    hca_qpc.qpc_seg11.rxt_mrc_dif_num = '0;  // 存放mrc信息： DIF 间接KLM模式下，dif_klm的总数 DIF MTT模式下，dif_pbl的总数
    hca_qpc.qpc_seg11.rxt_mrc_data_num_bp = '0;  // DIF 间接KLM模式下，当前已使用的data_klm_num DIF MTT模式下，当前已使用的data_pbl_num
    hca_qpc.qpc_seg11.rxt_mrc_dif_num_bp = '0;  // DIF 间接KLM模式下，当前已使用的dif_klm num DIF MTT模式下，当前已使用的dif_pbl num
    hca_qpc.qpc_seg11.rxt_mrc_dif_va = '0;  // DIF KLM模式下dif_sge的断点 DIF MTT模式下dif_pbl的断点
    hca_qpc.qpc_seg11.rxt_mrc_dif_key = '0;  // DIF KLM模式下dif_sge的断点 DIF MTT模式下rsv
    hca_qpc.qpc_seg11.rxt_mrc_dif_len = veroce_en ? {8'b0,hca_qpc.start_ssn-1} : '0;  // DIF KLM模式下dif_sge的断点 DIF MTT模式下dif_pbl的断点 veRoCE场景： [23:0]：复用为rxt_req_right_msn，接收有效请求的右边界msn [30:24]：rsv [31:31]：复用为rxt_sack_th_flag，接收请求达到阈值，触发SACK门铃时拉高，rxt_req_left_psn超过rxt_sack_right_psn时拉低
    hca_qpc.qpc_seg11.rxt_dif_dmalen = veroce_en ? {8'b0,hca_qpc.qpc_seg00.rcv_start_psn-1} : '0;  // DIF模式下的待收包长度，用于校验message总长度 veRoCE场景： [23:0]：复用为rxt_sack_right_psn，接收请求达到阈值或者TMO，SACK的右边界 [31:24]：复用为rxt_sack_send_cnt，接收请求达到阈值或者TMO，触发SACK门铃时cnt++
    hca_qpc.qpc_seg11.swcc_timestamp = '0;  // RoCE/veRoCE场景下，ECN为10时上报SWCC事件的时间戳，单位ms
    hca_qpc.qpc_seg11.swcc_timestamp_vld = '0;  // SWCC时间戳有效

    // ── seg 12 ──
    hca_qpc.qpc_seg12.rxt_qp_state = 4'h3;  // RX T端的qp_state： 4'h3：RTS； 4'h6：Error； other：unkown。
    hca_qpc.qpc_seg12.rxt_resp_wr_ptr = veroce_en ? hca_qpc.start_ssn[8:0]-1 : '0;  // resp写指针
    hca_qpc.qpc_seg12.rxt_rq_flush_flag = '0;  // 以下情况下拉高，用于TX_WQE进行RQ FLUSH流程处理 1，rq_type为rq时，当前已上报flush CQE 2，rq_type为srq时，当前已上报last_wqe CQE 3，rq_type为no_rq时，当前已收到过fake_flush
    hca_qpc.qpc_seg12.rxt_syn_to_wqe_err_flag = '0;  // T端UD置错或者收到置错fake时拉高，用于TX_WQE进行RQ FLUSH流程处理
    hca_qpc.qpc_seg12.rxt_cnp_phase_flag = '0;  // [3:0]对应PATH3~PATH0，对应PATH需要调度CNP包时，对应bit翻转为~txwqe_txt_cnp_phase_tag[]
    hca_qpc.qpc_seg12.rxt_rsp_retry_phase_flag = '0;  // veRoCE场景：rsp长超时重传flag，每次触发新的go back n重传时翻转为~txeng_rsp_retry_phase_flag（待TXENG补充）
    hca_qpc.qpc_seg12.rxt_path_index = '0;  // veRoCE场景：请求包中的sport对应路径，用于TX调度ack/nak/sack/cnp/rtt时选择对应的path_id
    hca_qpc.qpc_seg12.rxt_ack_syndrome = '0;  // 同步给TX的ACK调度请求syndrome信息
    hca_qpc.qpc_seg12.rxt_resp_newest_psn = hca_qpc.qpc_seg00.rcv_start_psn-1;  // 需要调度响应包的最新psn veRoCE场景：接收请求的最新psn
    hca_qpc.qpc_seg12.rxt_rmsn = hca_qpc.start_ssn-1;  // 响应程序的当前消息序列号 veRoCE场景：接收请求的最新msn
    hca_qpc.qpc_seg12.rxt_newest_credit = '0;  // 响应测最新的credit
    hca_qpc.qpc_seg12.rxt_nak_phase_flag = '0;  // 当前调度NAK包
    hca_qpc.qpc_seg12.rxt_ack_retry_phase_flag = '0;  // RX收到重传请求需要回ack的标识位
    hca_qpc.qpc_seg12.rxt_resp_retry_cnt = '0;  // RX收到重传Read/Atomic请求后，校验有效重传时更新的重传计数，每次触发新的重传cnt++
    hca_qpc.qpc_seg12.rxt_resp_retry_start_ptr = '0;  // RX收到重传Read/Atomic请求后，校验有效重传时更新的重传起始指针
    hca_qpc.qpc_seg12.rxt_resp_retry_end_ptr = '0;  // RX收到重传Read/Atomic请求后，校验有效重传时更新的重传结束指针（next ptr，不需要发）
    hca_qpc.qpc_seg12.rxt_sel_retry_cnt = '0;  // 选择性重传时，维护收到的重传Read Req重传计数，每次触发新的重传cnt++ veRoCE场景：选择性重传计数，每次触发新的选择性重传cnt++
    hca_qpc.qpc_seg12.rxt_sel_retry_start_ptr = '0;  // 选择性重传时，维护收到的重传Read Req空洞起点，判定新的重传时更新
    hca_qpc.qpc_seg12.rxt_sel_retry_end_ptr = '0;  // 选择性重传时，维护收到的重传Read Req空洞结尾，判定新的重传时更新（next ptr，不需要发）
    hca_qpc.qpc_seg12.rxt_hw_counter_completed = '0;  // 已上报CQE的个数，指向下一个即将消耗的hw_counter
    hca_qpc.qpc_seg12.rxt_rqe_uncompleted_flag = '0;  // 当前有已使用的RQE未上报CQE
    hca_qpc.qpc_seg12.rxt_resp_rd_flag = '0;  // RX TAG模块发起resp cache重传读的标识
    hca_qpc.qpc_seg12.rxt_resp_boundary_done = '0;  // 指示当前resp cache已经写完一轮
    hca_qpc.qpc_seg12.rxt_dif_cqe_record = '0;  // 指示当前是否已上报过DIF ERR的CQE，避免重复上报
    hca_qpc.qpc_seg12.rxt_nak_record = '0;  // 指示当前是否已回过NAK，接收预期请求后拉低
    hca_qpc.qpc_seg12.rxt_dc_disconnect_flag = veroce_en ? 1 : '0;  // 断链包标识 veRoCE场景：复用为rxt_rsp_upsn_synced，表示rxt_rsp_left_psn已完成同步
    hca_qpc.qpc_seg12.rxt_tmo_sfid = '0;  // DCR超时对应的SFID veRoCE场景：复用为rxt_remote_sport_h，远端UDP source port 高10bit（用于VeRoCE多路径返回CNP 和RTT Prob 及ACK）
    hca_qpc.qpc_seg12.rxt_tmo_dctn = hca_qpc.qpc_seg00.rcv_start_psn;  // DCR超时对应的DCTN veRoCE场景：复用为rxt_rsp_left_psn，接收ack_rsp/sack_rsp的左边界，即最早未应答的rsp_upsn
    hca_qpc.qpc_seg12.rxt_tmo_smac_7_0 = '0;  // DCR超时对应的SMAC veRoCE场景：复用为rxt_rsp_retry_len，rsp的重传区间
    hca_qpc.qpc_seg12.rxt_tmo_smac_39_8 = '0;  // DCR超时对应的SMAC veRoCE场景： [25:24]复用为rxt_remote_sport_rr_ptr，用于RXT sport无法匹配时，RR替换对应的entry [23:18]复用为rxt_remote_sport_l_3，远端路径四 UDP source port 低6bit （用于VeRoCE多路径返回CNP 和RTT Prob 及ACK） [17:12]复用为rxt_remote_sport_l_2，远端路径三 UDP source port 低6bit （用于VeRoCE多路径返回CNP 和RTT Prob 及ACK） [11: 6 ]复用为rxt_remote_sport_l_1，远端路径二 UDP source port 低6bit （用于VeRoCE多路径返回CNP 和RTT Prob 及ACK） [ 5 : 0 ]复用为rxt_remote_sport_l_0，远端路径一 UDP source port 低6bit （用于VeRoCE多路径返回CNP 和RTT Prob 及ACK）
    hca_qpc.qpc_seg12.rxt_tmo_smac_47_40 = '0;  // DCR超时对应的SMAC
    hca_qpc.qpc_seg12.rxt_tmo_sqpn = hca_qpc.qpc_seg00.rcv_start_psn-1;  // DCR超时对应的SQPN veRoCE场景：复用为rxt_rsp_newest_psn，需要调度rsp的最新psn，用于写resp cache的起始psn
    hca_qpc.qpc_seg12.rxt_tmo_stamp = '0;  // DCR超时时间戳，单位us
    hca_qpc.qpc_seg12.rxt_cnp_timestamp = '0;  // rx上一次收到报文带拥塞标记调度cnp的时间点，单位us
    hca_qpc.qpc_seg12.rxt_err_psn = '0;  // 出现致命错误的psn
    hca_qpc.qpc_seg12.rxt_err_syndrome = '0;  // 出现致命错误的类型
    hca_qpc.qpc_seg12.rxt_err_code = '0;  // 出现致命错误的原因
    hca_qpc.qpc_seg12.rxt_err_flag = '0;  // 出现致命错误flag
    hca_qpc.qpc_seg12.rxt_err_aecode = '0;  // 出现致命错误的子类型
    hca_qpc.qpc_seg12.rxt_hole_db_flag = '0;  // 乱序接收时，当前空洞是否按过响应门铃的标识位 veRoCE场景：复用为rxt_err_cqe_en，出现错误的上报事件类型
    hca_qpc.qpc_seg12.rxt_wait_db_cnt = '0;  // 乱序接收时，上次按门铃后，接收的未按门铃的请求计数
    hca_qpc.qpc_seg12.rxt_sel_retry_hole_vld = '0;  // 选择性重传时，暂存重传read首包携带的空洞信息，待同步给TX
    hca_qpc.qpc_seg12.rxt_sel_retry_hole_ptr = '0;  // 选择性重传时，暂存重传read首包携带的空洞信息，待同步给TX
    hca_qpc.qpc_seg12.rxt_sel_retry_hole_psn = veroce_en ? hca_qpc.start_ssn-1 : '0;  // 选择性重传时，暂存重传read首包携带的空洞信息，待同步给TX veRoCE场景：复用为rxt_rsp_amsn，确认已完成的rsp_msn，[7:0]重传的起始ptr
    hca_qpc.qpc_seg12.rxt_sel_retry_hole_cnt = '0;  // 选择性重传时，暂存重传read首包携带的空洞信息，待同步给TX
    hca_qpc.qpc_seg12.rxt_req_left_psn = hca_qpc.qpc_seg00.rcv_start_psn;  // 乱序接收时，当前收请求的空洞起点 veRoCE场景：复用为rxt_err_msn，出现错误的msn
    hca_qpc.qpc_seg12.rxt_req_cnt = '0;  // 乱序接收时，当前收请求的空洞长度
    hca_qpc.qpc_seg12.rxt_cnp_timestamp_vld = '0;  // 调度cnp的时间戳有效标识
    hca_qpc.qpc_seg12.rxt_cnp_path_bitmap = '0;  // 记录当前GAP内，对应path是否已调度CNP，避免多次门铃
    hca_qpc.qpc_seg12.rxt_a_max_psn_vld = '0;  // 乱序接收时，带A bit的请求右边界有效
    hca_qpc.qpc_seg12.rxt_a_max_psn = '0;  // 乱序接收时，带A bit的请求右边界
    hca_qpc.qpc_seg12.rxt_read_max_psn_vld = '0;  // 乱序接收时，read请求右边界有效
    hca_qpc.qpc_seg12.rxt_read_max_psn = hca_qpc.qpc_seg00.rcv_start_psn-1;  // 乱序接收时，read请求右边界 veRoCE场景：复用为rxt_rmsn_last_psn，记录已应答MSG的last_psn
    hca_qpc.qpc_seg12.rxt_dif_data = '0;  // 暂存DIF的中间结果 veRoCE场景：[127:0]复用为rxt_rsp_bitmap，接收ack_rsp/sack_rsp的bitmap

    // ── seg 13 ──
    hca_qpc.qpc_seg13.sq_ref_tag_m = '0;  // 该域段记录的是本轮数据计算完成后的lba的断点值(内存测)。记录的都是递增值
    hca_qpc.qpc_seg13.sq_crc_seed_m = '0;  // 计算CRC时所需的seed值。该域段记录的是本轮数据计算完成后的CRC的断点值(内存测)。
    hca_qpc.qpc_seg13.sq_cks_seed = '0;  // 计算CKS时所需的seed值。该域段记录的是本轮数据计算完成后的CKS的断点值。
    hca_qpc.qpc_seg13.sq_ref_tag_w = '0;  // 该域段记录的是本轮数据计算完成后的lba的断点值。(网络侧)。记录的都是递增值
    hca_qpc.qpc_seg13.sq_crc_seed_w = '0;  // 计算CRC时所需的seed值。该域段记录的是本轮数据计算完成后的CRC的断点值(网络侧)。
    hca_qpc.qpc_seg13.sq_break_point = '0;  // block数据块的长度。该域段记录的是本轮数据结束后，所在该block块数据的位置。
    hca_qpc.qpc_seg13.sq_bp_remian_dif_vld = '0;  // add模式下，当发送给txeng的报文信用受限后存的dif数据
    hca_qpc.qpc_seg13.sq_bp_remian_dif_iscrc = '0;  // add模式下，当发送给txeng的报文信用受限后存的dif数据，指示guard_tag是crc还是cks
    hca_qpc.qpc_seg13.sq_type = '0;  // 0：表示是SQ 1：表示是RQ

    // ── seg 14 ──
    hca_qpc.qpc_seg14.rq_retry_ref_tag_m = '0;  // 该域段记录的是本轮数据计算完成后的lba的断点值(内存测)。记录的都是递增值 Veroce：TMO复用31:0用于记录长超时0信息的timer值；
    hca_qpc.qpc_seg14.rq_retry_crc_seed_m = '0;  // 计算CRC时所需的seed值。该域段记录的是本轮数据计算完成后的CRC的断点值(内存测)。 Veroce：TMO复用15:0用于记录长超时0的PSN[15:0]；
    hca_qpc.qpc_seg14.rq_retry_cks_seed = '0;  // 计算CKS时所需的seed值。该域段记录的是本轮数据计算完成后的CKS的断点值。 Veroce：TMO复用23:16用于记录长超时0的PSN[23:16]； Veroce：TMO复用25:24用于记录长超时0的类型；
    hca_qpc.qpc_seg14.rq_retry_ref_tag_w = '0;  // 该域段记录的是本轮数据计算完成后的lba的断点值。(网络侧)。记录的都是递增值 Veroce：TMO复用31:0用于记录长超时1信息的timer值；
    hca_qpc.qpc_seg14.rq_retry_crc_seed_w = '0;  // 计算CRC时所需的seed值。该域段记录的是本轮数据计算完成后的CRC的断点值(网络侧)。 Veroce：TMO复用15:0用于记录长超时1的PSN[15:0]；
    hca_qpc.qpc_seg14.rq_retry_break_point = '0;  // block数据块的长度。该域段记录的是本轮数据结束后，所在该block块数据的位置。 Veroce：TMO复用23:16用于记录长超时1的PSN[23:16]； Veroce：TMO复用25:24用于记录长超时1的类型；
    hca_qpc.qpc_seg14.rq_retry_bp_remian_dif_vld = '0;  // add模式下，当发送给txeng的报文信用受限后存的dif数据
    hca_qpc.qpc_seg14.rq_retry_bp_remian_dif_iscrc = '0;  // add模式下，当发送给txeng的报文信用受限后存的dif数据，指示guard_tag是crc还是cks
    hca_qpc.qpc_seg14.rq_retry_type = '0;  // 0：表示是SQ 1：表示是RQ

    // ── seg 15 ──
    hca_qpc.qpc_seg15.rq_ref_tag_m = '0;  // 该域段记录的是本轮数据计算完成后的lba的断点值(内存测)。记录的都是递增值 Veroce：TMO复用31:0用于记录短超时信息的timer值；
    hca_qpc.qpc_seg15.rq_crc_seed_m = '0;  // 计算CRC时所需的seed值。该域段记录的是本轮数据计算完成后的CRC的断点值(内存测)。 Veroce：TMO复用15:0用于记录短超时的PSN[15:0]；
    hca_qpc.qpc_seg15.rq_cks_seed = '0;  // 计算CKS时所需的seed值。该域段记录的是本轮数据计算完成后的CKS的断点值。 Veroce：TMO复用23:16用于记录短超时的PSN[23:16]；
    hca_qpc.qpc_seg15.rq_ref_tag_w = '0;  // 该域段记录的是本轮数据计算完成后的lba的断点值。(网络侧)。记录的都是递增值
    hca_qpc.qpc_seg15.rq_crc_seed_w = '0;  // 计算CRC时所需的seed值。该域段记录的是本轮数据计算完成后的CRC的断点值(网络侧)。
    hca_qpc.qpc_seg15.rq_break_point = '0;  // block数据块的长度。该域段记录的是本轮数据结束后，所在该block块数据的位置。
    hca_qpc.qpc_seg15.rq_bp_remian_dif_vld = '0;  // add模式下，当发送给txeng的报文信用受限后存的dif数据
    hca_qpc.qpc_seg15.rq_bp_remian_dif_iscrc = '0;  // add模式下，当发送给txeng的报文信用受限后存的dif数据，指示guard_tag是crc还是cks
    hca_qpc.qpc_seg15.rq_type = '0;  // 0：表示是SQ 1：表示是RQ

    // ── seg 16 ──
    hca_qpc.qpc_seg16.cc_rc = '0;  // DCQCN拥塞控制算法参数—当前速率，表示源端发送速率，rc通过乘法计算得出。其中0表示满速
    hca_qpc.qpc_seg16.cc_rt = '0;  // DCQCN拥塞控制算法参数—目标速率，用于计算rc的参数
    hca_qpc.qpc_seg16.cc_alpha = '0;  // DCQCN拥塞控制算法参数—alpha，值越大，表明网络拥塞越严重，降速幅度大；反之表明网络拥塞不严重，降速幅度小
    hca_qpc.qpc_seg16.cc_tc = '0;  // DCQCN拥塞控制算法参数—TIMER阈值计数，累加某条QP在未遇到降速之前的超时加速的个数，累加到31后保持不变
    hca_qpc.qpc_seg16.cc_bc = '0;  // DCQCN拥塞控制算法参数—字节数阈值计数，累加某条QP在未遇到降速之前的字节数加速的个数，累加到31后保持不变
    hca_qpc.qpc_seg16.cc_alpha_cnt = '0;  // 用于降低或增快alpha变化的频率
    hca_qpc.qpc_seg16.cc_dfx_add_hw_flag = '0;  // 用于判断该表项对应qp对应dfx计数器是否加1。创建时mq需将其置0
    hca_qpc.qpc_seg16.cc_ts_l = '0;  // timer时间戳低17bit，以us为粒度，用于防止超时误加速
    hca_qpc.qpc_seg16.cc_bc_clr_flag = '0;  // DCQCN拥塞控制算法收到CNP翻转以清除字节数计数。当TX_ENG与该信号值不同，清除字节计数；反之，TX_ENG继续累加字节数
    hca_qpc.qpc_seg16.cc_cc_ctrl_en = '0;  // DCQCN拥塞控制算法某条QP是否处于拥塞管理。1表示某条QP处于拥塞管理之下，0表示某条QP不处于拥塞管理之下
    hca_qpc.qpc_seg16.cc_ts_h = '0;  // timer时间戳高5bit，以us为粒度，用于防止超时误加速
    hca_qpc.qpc_seg16.checksum = '0;  // 在回写nic_qpc_cache与load回nic_qpc_cache时，进行checksum校验的域段（与CC共用一个分片，CC不关注）。

endtask
