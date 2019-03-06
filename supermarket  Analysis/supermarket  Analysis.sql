﻿-- 1.地理位置分析。（本来应该从大区分析到门店，但因为数据的问题，一个大区里面只有一个门店，所以就不分析门店了）
--   地理位置的信息是在test_dw.dim_shop表里，分析的指标（销售额，销售量，促销额，有效客流量）信息在test_dw.fct_sales_item表里。
select b.areaCode,b.areaName
      ,sum(a.AMT) as area_amt
      ,sum(a.QTY) as area_qty
      ,sum(a.pAMT) as area_pamt
      ,count(distinct a.salesNo) as area_kl  -- 因为此处内连接的键dimShopID是多对一的，所以salesNo不会有重复，不用distinct也一样
from test_dw.fct_sales_item a 
inner join test_dw.dim_shop as b on a.dimShopID=b.dimShopID
where a.dimDateID between 20170801 and 20170831
group by b.areaCode,b.areaName

select (1719275.87000-1595530.23000)/1595530.23000*100
-- 结论：北京大区整体指标都比华东大区好，如果按销售额来衡量，北京大区比华东大区高7.75% 

-- 1.1疑问：分析各大区情况，用不用连接商品表test_dw.dim_goods。
--        我尝试连接了之后，把结果对比，发现只有销售量即area_qty减少，其他3个量都不变，为什么呢？
--        如果是因为内连接（要交集，有的行test_dw.fct_sales_item表里有，但是test_dw.dim_goods表没有，就省略了），
--        那应该4个变量都减少才对啊？
select b.areaCode,b.areaName
      ,sum(a.AMT) as area_amt
      ,sum(a.QTY) as area_qty
      ,sum(a.pAMT) as area_pamt
      ,count(distinct a.salesNo) as area_kl
from test_dw.fct_sales_item a 
inner join test_dw.dim_shop as b on a.dimShopID=b.dimShopID
inner join test_dw.dim_goods as c on a.goodsID= c.dimGoodsID
where a.dimDateID between 20170801 and 20170831
group by b.areaCode,b.areaName




-- 2.商品分析。用的是test_dw.dim_goods表和test_dw.fct_sales_item表。
--   2.1 分析品类（按第3类，因为第2类太粗，第4类太细）
select b.categoryName3
      ,sum(a.AMT) as area_amt
      ,sum(a.QTY) as area_qty
      ,sum(a.pAMT) as area_pamt
      ,count(distinct a.salesNo) as area_kl
from test_dw.fct_sales_item as a 
inner join test_dw.dim_goods as b on a.goodsID=b.dimGoodsID
where a.dimDateID between 20170801 and 20170831
group by b.categoryName3
order by area_amt desc 
-- 结论：4个指标统一，最高的3个品类是香烟，礼盒酒，葡萄酒、果酒、香槟酒

--   2.2 看看‘香烟’这一品类下的各个商品的品牌情况。
select b.categoryName3,b.branName
      ,sum(a.AMT) as area_amt
      ,sum(a.QTY) as area_qty
      ,sum(a.pAMT) as area_pamt
      ,count(distinct a.salesNo) as area_kl
from test_dw.fct_sales_item as a 
inner join test_dw.dim_goods as b on a.goodsID=b.dimGoodsID
where a.dimDateID between 20170801 and 20170831 
group by b.categoryName3,b.branName
order by b.categoryName3 desc ,area_amt desc  
--   结论：品牌branName中，空的表示数据缺失，即它们可以是其他品牌，因此，这里有漏洞，不能说明那个品牌最好。

--   2.3 取出销售额最高的20个商品
select b.dimGoodsID,b.name
      ,sum(a.AMT) as area_amt
from test_dw.fct_sales_item as a 
inner join test_dw.dim_goods as b on a.goodsID=b.dimGoodsID
where a.dimDateID between 20170801 and 20170831 
group by b.dimGoodsID,b.name
order by area_amt desc 
limit 20
--   结论：销售额最高的3个产品是：三江购物大豆油5L，苏北米(散装)，鲜鸡蛋。都是一些生活必需品



-- 3.时间分析。用两个表：test_dw.fct_sales 和test_dw.dim_date。
--   3.1 看看一周中哪几天销售额最高。
select b.weekdayCode,b.weekdayName
      ,sum(a.AMT) as area_amt
      ,sum(a.QTY) as area_qty
      ,sum(a.pAMT) as area_pamt
      ,count(distinct a.salesNo) as area_kl
from test_dw.fct_sales as a 
inner join test_dw.dim_date as b on a.dimDateID=b.dimDateID
group by b.weekdayCode,b.weekdayName
order by area_amt desc 
--   结论：周2周3最高，与常识相反周6最低。

--   3.2 随月变化趋势。
select b.monthCode,b.monthName
      ,sum(a.AMT) as area_amt
      ,sum(a.QTY) as area_qty
      ,sum(a.pAMT) as area_pamt
      ,count(distinct a.salesNo) as area_kl
from test_dw.fct_sales as a 
inner join test_dw.dim_date as b on a.dimDateID=b.dimDateID
group by b.monthCode,b.monthName
--   结论：销售额在降低，销售量增加，客流量稳定。 促销额对销售额的拉动作用明显，6月的促销额和销售额都明显高于其他月分。


-- 4 会员分析。
--   4.1 会员的年龄分布。先查看年龄的最小最大值。
select min(a.age) ,max(a.age)
from
(select b.dimMemberID
      ,year(curdate())-year(convert(b.birthDate,date)) as age
from test_dw.fct_sales as a 
inner join test_dw.dim_member as b on a.dimMemberID=b.dimMemberID
group by b.dimMemberID)
as a 
--   结论：最小年龄6岁，最大年龄105岁

--   4.2 以20为区间：6-25,   25-45，   45-65，   65-85 ，   85-105   

select 
       count( if(c.age>5 and c.age<=25, c.dimMemberID,null)) as 1_qujian
      ,count(if(c.age>25 and c.age<=45,c.dimMemberID,null)) as 2_qujian
      ,count(if(c.age>45 and c.age<=65,c.dimMemberID,null)) as 3_qujian
      ,count(if(c.age>65 and c.age<=85,c.dimMemberID,null)) as 4_qujian
      ,count(if(c.age>85 and c.age<=105,c.dimMemberID,null)) as 5_qujian
from      
	(select b.dimMemberID
	      ,year(curdate())-year(convert(b.birthDate,date)) as age
	      ,sum(a.AMT) as area_amt
	      ,sum(a.QTY) as area_qty
	      ,sum(a.pAMT) as area_pamt
	      ,count(distinct a.salesNo) as area_kl
	from test_dw.fct_sales as a 
	inner join test_dw.dim_member as b on a.dimMemberID=b.dimMemberID
	group by b.dimMemberID) as c 
union all 
select 
       sum(if(c.age>5 and c.age<=25, c.area_amt,0)) as 1_qujian
      ,sum(if(c.age>25 and c.age<=45,c.area_amt,0)) as 2_qujian
      ,sum(if(c.age>45 and c.age<=65,c.area_amt,0)) as 3_qujian
      ,sum(if(c.age>65 and c.age<=85,c.area_amt,0)) as 4_qujian
      ,sum(if(c.age>85 and c.age<=105,c.area_amt,0)) as 5_qujian
from      
	(select b.dimMemberID
	      ,year(curdate())-year(convert(b.birthDate,date)) as age
	      ,sum(a.AMT) as area_amt
	      ,sum(a.QTY) as area_qty
	      ,sum(a.pAMT) as area_pamt
	      ,count(distinct a.salesNo) as area_kl
	from test_dw.fct_sales as a 
	inner join test_dw.dim_member as b on a.dimMemberID=b.dimMemberID
	group by b.dimMemberID) as c 
--   结论：各区间的会员数和会员销售额无明显差别。
--   疑问：按理说，20岁以下的年轻人很少会办会员，他们没钱啊

--   验证一下人数有没有错：	
select count(d.dimMemberID)
from
(select b.dimMemberID
      ,year(curdate())-year(convert(b.birthDate,date)) as age
from test_dw.fct_sales as a 
inner join test_dw.dim_member as b on a.dimMemberID=b.dimMemberID
group by b.dimMemberID) as d 
where d.age<=25
--   都是2218个人，看来没错

--   4.2 会员贡献率
select sum(if(aa.dimMemberID!=0,aa.AMT,0))/sum(aa.AMT) as 会员贡献率
from test_dw.fct_sales as aa 
--   结论：会员的销售额占总体销售额的66%

--   4.3 RFM分析。取最近一个月，即20170801-20170831 
--       R：最近购买时间在一个星期内，即时间大于20170822，的会员取1，否则取0
--       F：在最近一个月内，购买频次大于5的会员取1，否则取0
--       M：在最近一个月内，消费额大于250的会员取1，否则取0
select  b.dimMemberID
       ,if(max(a.dimDateID)>=@r,1,0) as R 
       ,if(count(distinct a.salesNo)>=5,1,0) as F 
       ,if(sum(a.AMT)>=250,1,0) as M 
from test_dw.fct_sales as a 
inner join test_dw.dim_member as b  on a.dimMemberID=b.dimMemberID
join(select @s := 20170801,@e := 20170831,@r :=20170822) as m 
where a.dimDateID>=@s and a.dimDateID<=@e
group by b.dimMemberID

--    取出优质会员
select c.dimMemberID,c.R,c.F,c.M
from 
	(select  b.dimMemberID
	       ,if(max(a.dimDateID)>=@r,1,0) as R 
	       ,if(count(distinct a.salesNo)>=5,1,0) as F 
	       ,if(sum(a.AMT)>=250,1,0) as M 
	from test_dw.fct_sales as a 
	inner join test_dw.dim_member as b  on a.dimMemberID=b.dimMemberID
	join(select @s := 20170801,@e := 20170831,@r :=20170822) as m 
	where a.dimDateID>=@s and a.dimDateID<=@e
	group by b.dimMemberID) as c 
where c.R=1 and c.F=1 and c.M=1

--   优质会员的数量,占比
select count(*) as rfm_num
      ,count(*)/
       (select count(distinct a.dimMemberID)
       from  test_dw.fct_sales as a 
	   inner join test_dw.dim_member as b  on a.dimMemberID=b.dimMemberID)  as rfm_v 
from 
(select c.dimMemberID,c.R,c.F,c.M
from 
	(select  b.dimMemberID
	       ,if(max(a.dimDateID)>=@r,1,0) as R 
	       ,if(count(distinct a.salesNo)>=5,1,0) as F 
	       ,if(sum(a.AMT)>=250,1,0) as M 
	from test_dw.fct_sales as a 
	inner join test_dw.dim_member as b  on a.dimMemberID=b.dimMemberID
	join(select @s := 20170801,@e := 20170831,@r :=20170822) as m 
	where a.dimDateID>=@s and a.dimDateID<=@e
	group by b.dimMemberID) as c 
where c.R=1 and c.F=1 and c.M=1) as d 





-- 二. 上面的都是单维度的分析。下面把不同的维度合起来，比如地理位置和商品，商品和会员等等，这样就可以有2维，3维，4维。从中选出几个来分析
--   5.地理位置+商品 ——> 各大区，分别销售额前10的商品。用到3个表：test_dw.fct_sales_item ，test_dw.dim_shop和test_dw.dim_goods
select ml.areaName,ml.dimGoodsID,ml.name
      ,ml.goods_amt
      ,ml.id
from 
	(select x.areaCode,x.areaName,x.dimGoodsID,x.name
	      ,x.goods_amt
	      ,@id := if(@area=x.areaName,@id+1,1) as id 
	      ,@area := x.areaName as area
	from 
		(select b.areaCode,b.areaName,c.dimGoodsID,c.name
		      ,sum(a.AMT) as goods_amt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_shop  as b on a.dimShopID=b.dimShopID
		inner join test_dw.dim_goods as c on a.goodsID=c.dimGoodsID
		join(select @id := 0,@area := '') as m 
		group by b.areaCode,b.areaName,c.dimGoodsID,c.name
		order by b.areaCode,b.areaName,goods_amt desc)  as x )  as ml 
where id <= 20
--  结论：在Excel中分析了这两组产品，有两个商品，在北京大区进前20，但在东北大区没进：散装糯米 和 黑鱼。 其余产品顺序前10的，略有变动，10到20的较大变化

--    把两个区的数据并到列上，好对比商品
select *
from 
	(select k.areaName,k.name,k.goods_amt
	      ,@id := @id +1 as id_b
	from 
		(select b.areaCode,b.areaName,c.dimGoodsID,c.name
		      ,sum(a.AMT) as goods_amt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_shop  as b on a.dimShopID=b.dimShopID
		inner join test_dw.dim_goods as c on a.goodsID=c.dimGoodsID
		join(select @id := 0) as m 
		where b.areaCode='BJOOOO'
		group by b.areaCode,b.areaName,c.dimGoodsID,c.name
		order by b.areaCode,b.areaName,goods_amt desc) as k 
	limit 20) as n 
inner join 
	(select k.areaName,k.name,k.goods_amt
	      ,@id := @id +1 as id_h
	from 
		(select b.areaCode,b.areaName,c.dimGoodsID,c.name
		      ,sum(a.AMT) as goods_amt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_shop  as b on a.dimShopID=b.dimShopID
		inner join test_dw.dim_goods as c on a.goodsID=c.dimGoodsID
		join(select @id := 0) as m 
		where b.areaCode='HDOOOO'
		group by b.areaCode,b.areaName,c.dimGoodsID,c.name
		order by b.areaCode,b.areaName,goods_amt desc) as k 
	limit 20) as h 
on n.id_b=h.id_h
--   因为执行顺序，要先执行on，再执行join，而h表，on的键是join那里创建的，所以这个没法实现。


--   5.2 商品+时间 ——> 一周中每天销售额最高的5个商品
--       用到3个表：test_dw.fct_sales_item ，test_dw.dim_date ，test_dw.dim_goods 
select g.weekdayName,g.name,g.wg_amt,g.id
from 
	(select d.weekdayCode,d.weekdayName,d.dimGoodsID,d.name
	      ,d.wg_amt
	      ,@id := if(@wk=d.weekdayName,@id+1,1) as id 
	      ,@wk:=d.weekdayName
	from 
		(select  b.weekdayCode,b.weekdayName,c.dimGoodsID,c.name
		       ,sum(a.AMT) as wg_amt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_date as b on a.dimDateID=b.dimDateID
		inner join test_dw.dim_goods as c on a.goodsID=c.dimGoodsID
		join(select @id := 0,@wk := '') as m 
		group by b.weekdayCode,b.weekdayName,c.dimGoodsID,c.name
		order by b.weekdayCode,b.weekdayName ,wg_amt desc) as d) 
as g 
where id <=5
--   结论：首先，这是6,7,8三个月的情况。有趣的地方：
--        1. 周5买烟的少了，销售额没有进前5
--        2. 周4有一特殊的商品‘利群（休闲）’，它在其他天销售额都没有进前5
--        3. 大体上，人们每天买的东西就是：油，米，烟，蛋，糖

--   5.3 会员+商品+地理位置——> 各地区的会员喜欢哪些商品
--       只需要在 5.1 的代码中连接test_dw.dim_member表即可，因为连接了这个表之后，每一条记录都是关于会员的了
select ml.areaName,ml.dimGoodsID,ml.name
      ,ml.goods_amt
      ,ml.id
from 
	(select x.areaCode,x.areaName,x.dimGoodsID,x.name
	      ,x.goods_amt
	      ,@id := if(@area=x.areaName,@id+1,1) as id 
	      ,@area := x.areaName as area
	from 
		(select b.areaCode,b.areaName,c.dimGoodsID,c.name
		      ,sum(a.AMT) as goods_amt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_shop  as b on a.dimShopID=b.dimShopID
		inner join test_dw.dim_goods as c on a.goodsID=c.dimGoodsID
		inner join test_dw.fct_sales as d on a.salesID=d.salesID
		inner join test_dw.dim_member as e  on d.dimMemberID=e.dimMemberID
		join(select @id := 0,@area := '') as m 
		group by b.areaCode,b.areaName,c.dimGoodsID,c.name
		order by b.areaCode,b.areaName,goods_amt desc)  as x )  as ml 
where id <= 20
--   结论：会员买的就是油，蛋，米，糖。特别的，烟的销售额在北京地区没进前10，在华东地区没进前20。结合前面的分析，会员的年龄分布均匀，可以推测会员跟多是女性。
--   不足：因为连接的表太多，上面代码运行时间太长，换为用筛选条件筛选出会员。
select ml.areaName,ml.dimGoodsID,ml.name
      ,ml.goods_amt
      ,ml.id
from 
	(select x.areaCode,x.areaName,x.dimGoodsID,x.name
	      ,x.goods_amt
	      ,@id := if(@area=x.areaName,@id+1,1) as id 
	      ,@area := x.areaName as area
	from 
		(select b.areaCode,b.areaName,c.dimGoodsID,c.name
		      ,sum(a.AMT) as goods_amt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_shop  as b on a.dimShopID=b.dimShopID
		inner join test_dw.dim_goods as c on a.goodsID=c.dimGoodsID
		inner join test_dw.fct_sales as d on a.salesID=d.salesID
		join(select @id := 0,@area := '') as m 
		where d.dimMemberID not in(0,1)
		group by b.areaCode,b.areaName,c.dimGoodsID,c.name
		order by b.areaCode,b.areaName,goods_amt desc)  as x )  as ml 
where id <= 20
--   耗时都一样


--   5.4 地理位置+会员——>各地区的会员数量，会员贡献率
--       用到表test_dw.fct_sales，test_dw.dim_shop，test_dw.dim_member
select b.areaCode,b.areaName
      ,count(distinct c.dimMemberID) as m_num
      ,sum(a.AMT)/(select sum(d.AMT) from test_dw.fct_sales as d ) as mv_atm
from test_dw.fct_sales as a 
inner join test_dw.dim_shop as b on a.dimShopID=b.dimShopID
inner join test_dw.dim_member as c on a.dimMemberID=c.dimMemberID
group by b.areaCode,b.areaName
--   结论：两大区会员数和贡献率都差不多。

--   5.5 会员+时间——>会员喜欢在哪几天买东西，用销售额来衡量。
--       用到表test_dw.fct_sales，test_dw.dim_member，test_dw.dim_date
select c.weekdayCode,c.weekdayName
      ,sum(a.AMT) as mw_amt
      ,count(distinct a.salesNo) as m_kl
from test_dw.fct_sales as a 
inner join test_dw.dim_date as c on a.dimDateID=c.dimDateID
where a.dimMemberID not in (0,1)
group by c.weekdayCode,c.weekdayName 
order by mw_amt desc 

select (1195160.04000-989062.38000)/989062.38000
--   结论：会员最爱购买的时间是周5和周2，消费额最高的周5比最低的周4高20%


--   5.6 商品分析。最高的10和20个商品占总体商品销售额的比例
select 
	(select sum(f.g_amt) 
    from 
		(select b.dimGoodsID,b.name
		      ,sum(a.AMT) as g_amt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_goods as b on a.goodsID=b.dimGoodsID
		group by b.dimGoodsID,b.name
		order by g_amt desc 
		limit 10) as f )/
	(select sum(a.AMT) 
     from test_dw.fct_sales_item as a ) as v_t10
--   看看前20个产品
select 
	(select sum(f.g_amt) 
    from 
		(select b.dimGoodsID,b.name
		      ,sum(a.AMT) as g_amt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_goods as b on a.goodsID=b.dimGoodsID
		group by b.dimGoodsID,b.name
		order by g_amt desc 
		limit 20) as f )/
	(select sum(a.AMT) 
     from test_dw.fct_sales_item as a ) as v_t20
--   商品总数
select count(distinct b.dimGoodsID) as g_num
from test_dw.fct_sales_item as a 
inner join test_dw.dim_goods as b on a.goodsID=b.dimGoodsID
--   结论：前20个商品占所有17346个商品销售额的22%

--   另外：验证一下2/8定理
select 17346*0.2;
select 
	(select sum(f.g_amt) 
    from 
		(select b.dimGoodsID,b.name
		      ,sum(a.AMT) as g_amt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_goods as b on a.goodsID=b.dimGoodsID
		group by b.dimGoodsID,b.name
		order by g_amt desc 
		limit 3000) as f )/
	(select sum(a.AMT) 
     from test_dw.fct_sales_item as a ) as v_t3000;
--   看来还真满足2/8定理：前3000个产品（20%）占所有产品销售额的79.7%


--   5.7 哪种商品最爱搞促销  
select b.dimGoodsID,b.name
      ,sum(a.pAMT) as g_pamt
      ,sum(a.mpAMT) as g_mpamt
from test_dw.fct_sales_item as a 
inner join test_dw.dim_goods as b on a.goodsID=b.dimGoodsID
group by b.dimGoodsID,b.name
order by g_pamt desc 
--   结论：最爱搞促销的商品依次是利群（休闲），中华(硬)，中华(软)，三江购物大豆油5L，他们3个月的促销金额大于10000元

select b.dimGoodsID,b.name
      ,sum(a.pAMT) as g_pamt
      ,sum(a.mpAMT) as g_mpamt
from test_dw.fct_sales_item as a 
inner join test_dw.dim_goods as b on a.goodsID=b.dimGoodsID
group by b.dimGoodsID,b.name
order by g_mpamt desc 
--   结论：对会员优惠最高的商品（也就是最吸引会员的商品）是三江购物大豆油5L，鲜鸡蛋，白砂糖(散)，香软粳米(散装)，散装东北大米(三江购物)。
--   综上所述，为何商场销量最高的商品是油，蛋，烟，米，糖，因为油，蛋，米，糖对会员优惠高，烟爱搞促销。

--   5.8 哪天爱搞促销
select b.weekdayName
      ,sum(a.pAMT) as w_pamt
from test_dw.fct_sales as a 
inner join test_dw.dim_date as b on a.dimDateID=b.dimDateID
group by b.weekdayName
order by w_pamt desc 
--   结论：周2和周4最爱搞促销，而销售额最高的是周2和周3，周4反而是倒数第二。说明销售额还有其他因素影响。

--   分区看看
select c.areaName,b.weekdayName
      ,sum(a.pAMT) as w_pamt
from test_dw.fct_sales as a 
inner join test_dw.dim_date as b on a.dimDateID=b.dimDateID
inner join test_dw.dim_shop as c on a.dimShopID=c.dimShopID
group by c.areaName,b.weekdayName
order by c.areaName,w_pamt desc 
--  可看出华东大区是周2和周3爱搞促销

select c.areaName,b.weekdayName
      ,sum(a.AMT) as w_amt
      ,count(distinct a.salesNo) as w_kl
from test_dw.fct_sales as a 
inner join test_dw.dim_date as b on a.dimDateID=b.dimDateID
inner join test_dw.dim_shop as c on a.dimShopID=c.dimShopID
group by c.areaName,b.weekdayName
order by c.areaName,w_amt desc
--   结论：两大区的销售额周3是第一高和第二高，看来除了促销还有别的因素使得周3的销售额高。


--   5.9 三个月里(6,7,8 )销售额增长最快的产品
select max(a.dimDateID) as ma 
      ,min(a.dimDateID) as mi 
from test_dw.fct_sales as a 
--   总共有90天，因为6月的开始是6月2日，所以，6月分：6月2日到7月1日，7月份：7月2日到7月31日，8月分：8-1到8-30

select f.name,f.7v6,f.8v7,f.8v6
from 
	(select d.dimGoodsID,d.name
	      ,(d.7_gamt-d.6_gamt)/d.6_gamt as 7v6
	      ,(d.8_gamt-d.7_gamt)/d.7_gamt as 8v7
	      ,(d.8_gamt-d.6_gamt)/d.6_gamt as 8v6
	from 
		(select c.dimGoodsID,c.name
		      ,sum(if(a.dimDateID>=20170602 and a.dimDateID<=20170701,a.AMT,0)) as 6_gamt
		      ,sum(if(a.dimDateID>=20170702 and a.dimDateID<=20170731,a.AMT,0)) as 7_gamt
		      ,sum(if(a.dimDateID>=20170801 and a.dimDateID<=20170830,a.AMT,0)) as 8_gamt
		from test_dw.fct_sales_item as a 
		inner join test_dw.dim_goods as c on a.goodsID=c.dimGoodsID
		group by c.dimGoodsID,c.name) 
	as d 
	where d.6_gamt!=0 and d.7_gamt!=0 and d.8_gamt!=0) 
as f 
where f.7v6>1 and f.8v7>1
--   结论：提取的这93种产品的各月间销售额增长超过100%


--   5.10 地理位置+时间+会员——>各地区各月会员贡献率和会员对折扣的享受比例的变化
select b.areaCode,b.areaName,d.monthCode,d.monthName
      ,sum(if(a.dimMemberID not in (0,1),a.AMT,0))/sum(a.AMT) as v_m_amt
      ,sum(if(a.dimMemberID not in (0,1),a.pAMT,0))/sum(a.pAMT) as v_m_pamt
from test_dw.fct_sales as a 
inner join test_dw.dim_shop as b on a.dimShopID=b.dimShopID
inner join test_dw.dim_date as d on a.dimDateID=d.dimDateID
group by b.areaCode,b.areaName,d.monthCode,d.monthName 
order by b.areaCode,d.monthCode;
--   结论：月数太少，看不出什么趋势，但两大区各月间贡献率的变化是同步的。 6月份的促销活动更针对会员


--    5.11 某种产品（如，香烟）各品牌销售额各地区排行
select b.areaCode,b.areaName,c.branName
      ,sum(a.AMT) as b_amt
      ,sum(a.pAMT) as b_pamt
from test_dw.fct_sales_item as a 
inner join test_dw.dim_shop as b on a.dimShopID=b.dimShopID
inner join test_dw.dim_goods as c on a.goodsID=c.dimGoodsID
where c.categoryName3= '香烟' and c.branName!=' '
group by b.areaCode,b.areaName,c.branName
order by b.areaCode,b.areaName ,b_amt desc ;
