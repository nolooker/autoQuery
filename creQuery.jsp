<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/jsp/common/include/taglibs.jsp"%>
<!DOCTYPE html> <html class="hidden"> <head><title>쿼리자동생성</title>
<%@ include file="/WEB-INF/jsp/common/include/meta.jsp"%>
<%@ include file="/WEB-INF/jsp/common/include/jqueryScript.jsp"%>
<%@ include file="/WEB-INF/jsp/common/include/ibSheetScript.jsp"%>
<script type="text/javascript" src="/common/js/cookie.js"></script>
<script type="text/javascript">
var gPRow = "";
var pGubun = "";
	$(function() {
	
		$("#searchTable").val("${cookie.hrQueryMgrTable.value}");
		
		$("input[type='text']").keydown(function(event){
			if(event.keyCode == 13){
				doAction1("Search");
			}
		});
		$("#chk").change(function(){
			if( sheet1.RowCount() > 0 ){
				makeInitSheet();
			}
		});
	
		//Sheet 초기화
		init_sheet1();
		$(window).smartresize(sheetResize); sheetInit();
		

		var sh = sheet1.GetSheetHeight()-250;
		$("#colList").height(sh);
		$("#selectQry").height(sh);
		$("#mergeQry").height(sh); 
		$("#initSheet").height(150);
	});


	function init_sheet1(){

		var initdata1 = {};
		initdata1.Cfg = {SearchMode:smLazyLoad,Page:22,MergeSheet:msHeaderOnly,DeferredHScroll:0};
		initdata1.HeaderMode = {Sort:1,ColMove:1,ColResize:1,HeaderCheck:0};

		initdata1.Cols = [
			{Header:"No",			Type:"${sNoTy}",	Hidden:1,	Width:"${sNoWdt}",	Align:"Center",	ColMerge:0,	SaveName:"sNo" },

			{Header:"COLUMN",		Type:"Text",		Hidden:0,	Width:100,	Align:"Left",	ColMerge:0,	SaveName:"columnName", Edit:0 },
			{Header:"COLUMN",		Type:"Text",		Hidden:0,	Width:80,	Align:"Left",	ColMerge:0,	SaveName:"columnName2", Edit:0 },
			{Header:"COMMENTS",		Type:"Text",		Hidden:0,	Width:100,	Align:"Left",	ColMerge:0,	SaveName:"comments", Edit:0 },
			{Header:"PK",			Type:"Text",		Hidden:0,	Width:45,	Align:"Center",	ColMerge:0,	SaveName:"pkYn", Edit:0 },
			{Header:"DATA_TYPE",	Type:"Text",		Hidden:0,	Width:100,	Align:"Left",	ColMerge:0,	SaveName:"dataType", Edit:0 },

		]; IBS_InitSheet(sheet1, initdata1);sheet1.SetEditable("${editable}");sheet1.SetVisible(true);sheet1.SetCountPosition(4);

	}


	//Sheet1 Action
	function doAction1(sAction) {
		switch (sAction) {
		case "Search":

			setCookie("hrQueryMgrTable",$("#searchTable").val(),1000);

			sheet1.DoSearch( "${ctx}/CreQueryMgr.do?cmd=getCreQueryMgrList", $("#sheet1Form").serialize());
			break;
		}
    }

	// 조회 후 에러 메시지
	function sheet1_OnSearchEnd(Code, Msg, StCode, StMsg) {
		try {
			if (Msg != "") {
				alert(Msg);
			}
			if( sheet1.RowCount() > 0 ){
				makeColumnList();
				makeSelectQry();
				makeMergeQry();
				makeDeleteQry();
			}
			sheetResize();
		} catch (ex) { alert("OnSearchEnd Event Error : " + ex); }
	}


	function sheet1_OnClick(Row, Col, Value) {
		try{

	  	}catch(ex){alert("OnClick Event Error : " + ex);}
	}


	function makeColumnList(){
		try{


			var query = "<table class='tableList'>";
			for(var i = sheet1.HeaderRows(); i < sheet1.RowCount()+sheet1.HeaderRows() ; i++) {

				query += "<tr><td class='td01'>"+sheet1.GetCellValue(i, "columnName2")+"</td><td class='td02'>"+sheet1.GetCellValue(i, "comments")+"</td>";
			}
			$("#colList").html(query+"</tr></table>");

	  	}catch(ex){alert("makeColumnList() Error : " + ex);}

	}


	var en = "\n";
	function makeSelectQry(){
		try{

			var tableNm = $("#searchTable").val().trim().toUpperCase();

			var query = "";
			query += "\t<!-- [업무명] 조회 -->"+en;
			query += "\t"+"<select parameterType=\"map\" resultType=\"cMap\" id=\"get쿼리명List\">"+en;
			query += "\t\t"+"<![CDATA["+en;
			query += "\t\t\t\tSELECT A.ENTER_CD"+en;
			for(var i = sheet1.HeaderRows(); i < sheet1.RowCount()+sheet1.HeaderRows() ; i++) {
				query += "\t\t\t\t     , A."+sheet1.GetCellValue(i, "columnName")+en;
			}
			query += "\t\t\t\t  FROM "+ tableNm+" A "+en;
			query += "\t\t\t\t WHERE A.ENTER_CD = TRIM(#"+"{ssnEnterCd})"+en;
			query += "\t\t"+"]]>"+en;
			query += "\t\t"+"<i"+"f test='paramNm != null and !paramNm.equals(\"\")'>"+en;
			query += "\t\t\t\t   AND A.PARAM_NM = TRIM( #"+"{paramNm} )"+en;
			query += "\t\t"+"</"+"if>"+en;
			query += "\t"+"</select>"+en;
			$("#selectQry").html(query);

	  	}catch(ex){alert("makeSelectQry() Error : " + ex);}

	}
	function makeMergeQry(){

		try{
			var tableNm = $("#searchTable").val().trim().toUpperCase();

			var query = "";
				query += "\t<!-- [업무명] 저장 -->"+en;
				query += "\t"+"<update parameterType=\"map\" id=\"save쿼리명\">"+en;
				query += "\t\t\t\tMERGE INTO "+tableNm+" T "+en;
				query += "\t\t\t\tUSING "+en;
				query += "\t\t\t\t( "+en;
				//query += "\t\t<bind name=\"icnt\" value=\"1\" /"+">"+en;
				query += '\t\t<foreach item="rm" collection="mergeRows" separator=" UNION ALL " index="icnt">'+en;
				query += "\t\t\t\t       SELECT TRIM(#"+"{ssnEnterCd}) AS ENTER_CD "+en+en+en;

				//query += "#if( $rm.seq && !$rm.seq.equals('') )"+en;

				query += "\t<!----[여기서부터] 필요 없을 시 삭제-------------------------------------------------->"+en;
				query += "\t\t\t<choose>"+en;
				query += "\t\t\t\t<when test='rm.seq != null and !rm.seq.equals(\"\")'>"+en;
				query += "\t\t\t\t            , TRIM(#"+"{rm.seq})  AS SEQ"+en;
				//query += "#else"+en;
				query += "\t\t\t\t</when>"+en;
				query += "\t\t\t\t<otherwise>"+en;
				query += "\t\t\t\t            , TO_CHAR( (SELECT (NVL(MAX(SEQ),0) + 1 + #"+"{icnt}) FROM "+tableNm+" WHERE ENTER_CD = #"+"{ssnEnterCd} ))  AS SEQ"+en;
				//query += "#set($icnt = $icnt + 1)"+en;
				//query += '\t\t\t\t\t<bind name="icnt" value="icnt + 1" /'+'>'+en;
				//query += "#end"+en+en+en;
				query += "\t\t\t\t</otherwise>"+en;
				query += "\t\t\t</choose>"+en;
			    query += "\t<!----[여기까지] 필요 없을 시 삭제-------------------------------------------------->"+en+en+en;

			for(var i = sheet1.HeaderRows(); i < sheet1.RowCount()+sheet1.HeaderRows() ; i++) {
				query += "\t\t\t\t            , TRIM(#"+"{rm."+sheet1.GetCellValue(i, "columnName2")+"}) AS "+sheet1.GetCellValue(i, "columnName")+en;
			}
			    query += "\t\t\t\t        FROM DUAL"+en;
				//query += "#if(!$mergeRows.size().equals("+"$"+"{velocityCount}) ) UNION ALL	 #end"+en;
				//query += "#end"+en;
				query += "\t\t</foreach>"+en;
				query += "\t\t\t\t) S "+en;
				query += "\t\t\t\tON ( "+en;
				query += "\t\t\t\t          T.ENTER_CD = S.ENTER_CD "+en;

			for(var i = sheet1.HeaderRows(); i < sheet1.RowCount()+sheet1.HeaderRows() ; i++) {
				if( sheet1.GetCellValue(i, "pkYn") == "Y" ){
				query += "\t\t\t\t     AND  T."+sheet1.GetCellValue(i, "columnName")+" = S."+sheet1.GetCellValue(i, "columnName")+" "+en;
				}
			}
				query += "\t\t\t\t) "+en;
				query += "\t\t\t\tWHEN MATCHED THEN "+en;
				query += "\t\t\t\t   UPDATE SET T.CHKDATE	= sysdate "+en;
				query += "\t\t\t\t            , T.CHKID	    = #"+"{ssnSabun} "+en;
			for(var i = sheet1.HeaderRows(); i < sheet1.RowCount()+sheet1.HeaderRows() ; i++) {
				if( sheet1.GetCellValue(i, "pkYn") == "N" ){
				query += "\t\t\t\t            , T."+sheet1.GetCellValue(i, "columnName")+" = S."+sheet1.GetCellValue(i, "columnName")+" "+en;
				}
			}
				query += "\t\t\t\tWHEN NOT MATCHED THEN "+en;
				query += "\t\t\t\t   INSERT "+en;
				query += "\t\t\t\t   ( "+en;
				query += "\t\t\t\t              T.ENTER_CD"+en;
			for(var i = sheet1.HeaderRows(); i < sheet1.RowCount()+sheet1.HeaderRows() ; i++) {
				query += "\t\t\t\t            , T."+sheet1.GetCellValue(i, "columnName")+""+en;
			}
				query += "\t\t\t\t            , T.CHKDATE"+en;
				query += "\t\t\t\t            , T.CHKID"+en;
				query += "\t\t\t\t   ) "+en;
				query += "\t\t\t\t   VALUES "+en;
				query += "\t\t\t\t   ( "+en;
				query += "\t\t\t\t              S.ENTER_CD"+en;
			for(var i = sheet1.HeaderRows(); i < sheet1.RowCount()+sheet1.HeaderRows() ; i++) {
				query += "\t\t\t\t            , S."+sheet1.GetCellValue(i, "columnName")+""+en;
			}
				query += "\t\t\t\t            , sysdate"+en;
				query += "\t\t\t\t            , #"+"{ssnSabun}"+en;
				query += "\t\t\t\t   ) "+en;
			query += "\t"+"</update>"+en;

			$("#mergeQry").html(query);

	  	}catch(ex){alert("makeMergeQry() Error : " + ex);}
	}

	function makeDeleteQry(){
		try{
			var query = "", tmp1 = "", tmp2 = "", tmp3 = "", tmp4 = "";

			for(var i = sheet1.HeaderRows(); i < sheet1.RowCount()+sheet1.HeaderRows() ; i++) {
				if( sheet1.GetCellValue(i, "pkYn") == "Y" ){
					var colnm= sheet1.GetCellValue(i, "columnName2");
					tmp1 += sheet1.GetCellValue(i, "columnName")+",";
					tmp2 += "NULL,";
					tmp3 += " rm." + colnm +" !=null and !rm."+ colnm + ".equals('') and";
					tmp4 += "TRIM( #"+"{rm." + colnm +"} ),";
				}
			}
			if( tmp1 == "" ) {
				$("#deleteQry").html("");
				return;
			}
			tmp1 = tmp1.substring(0, tmp1.length-1);
			tmp2 = tmp2.substring(0, tmp2.length-1);
			tmp3 = tmp3.substring(0, tmp3.length-3);
			tmp4 = tmp4.substring(0, tmp4.length-1);

			query += "\t<!-- [업무명] 삭제 -->"+en;
			query += "\t"+"<delete parameterType=\"map\" id=\"delete쿼리명\">"+en;

			query += "\t\t\t\tDELETE FROM "+$("#searchTable").val().toUpperCase()+en;
			query += "\t\t\t\t WHERE ENTER_CD = TRIM(#"+"{ssnEnterCd}) "+en;
			query += "\t\t\t\t   AND ( " + tmp1 + " ) IN ( ( " + tmp2 + ") "+en;
			query += '\t\t<foreach item="rm" collection="deleteRows" > '+en;
			query += "\t\t\t<if test=\"" + tmp3 + "\">"+en;
			query += "\t\t\t\t     , ( " + tmp4 + " ) "+en;
			query += "\t\t\t</if>"+en;
			query += "\t\t</foreach>"+en;
			query += "\t\t\t\t       )"+en;
			query += "\t"+"</delete>"+en;

			$("#deleteQry").html(query);

	  	}catch(ex){alert("makeDeleteQry() Error : " + ex);}

	}

	function makeInitSheet(){
		try{
			//{Header:"비고|비고", Type:"Text", Hidden:0, Width:100, Align:"Center", SaveName:"note", KeyField:0, Format:"", UpdateEdit:1, InsertEdit:1 },
			var query = "";

			for(var i = sheet1.HeaderRows(); i < sheet1.RowCount()+sheet1.HeaderRows() ; i++) {
				var title = sheet1.GetCellValue(i, "comments");
				var colnm = sheet1.GetCellValue(i, "columnName2");
				var type = "Text";
				var format = "";
				var colnm = sheet1.GetCellValue(i, "columnName");
				var colnm2 = sheet1.GetCellValue(i, "columnName2");
				var dataLength = sheet1.GetCellValue(i, "dataLength");

				var updateEdit = sheet1.GetCellValue(i, "pkYn") == "Y" ? "0" : "1";
				var keyField = sheet1.GetCellValue(i, "pkYn") == "Y" ? "1" : "0";
				var width = 100;
				if( $("#chk").is(":checked") ){
					title = title +"|"+ title;
				}
				if(colnm.includes("DATE")){
					type = "Date";
					width = "80";
					if(sheet1.GetCellValue(i, "dataType") == ("VARCHAR2(8)")){
						format = "Ymd";
						dataLength = 10;
					}else if(sheet1.GetCellValue(i, "dataType") == ("VARCHAR2(6)")){
						format = "Ym";
						dataLength = 8;
					}
				}else if(colnm.includes("_YMD") || colnm.includes("SYMD") || colnm.includes("EYMD")){
					if(sheet1.GetCellValue(i, "dataType") == ("VARCHAR2(8)")){
						type = "Date";
						format = "Ymd";
						width = "80";
						dataLength = 10;
					}
				}else if(colnm.includes("_YM")){
					if(sheet1.GetCellValue(i, "dataType") == ("VARCHAR2(6)")){
						type = "Date";
						format = "Ym";
						width = "80";
						dataLength = 8;
					}
				}else if(colnm.substr(colnm.length-3, colnm.length) == "_CD"){
					type="Combo";
				}else if(colnm.substr(colnm.length-4, colnm.length) == "_CNT"){
					type="Int";
				}else if(colnm.substr(colnm.length-3, colnm.length) == "_YN"){
					type="CheckBox";
				}else if(colnm == "RATE" || colnm.substr(colnm.length-5, colnm.length) == "_RATE"){
					type="Float";
					format = "#,##0.#";
				}else if(colnm.substr(colnm.length-5, colnm.length) == "_YYYY" || colnm.substr(colnm.length-5, colnm.length) == "_YEAR"){
					type="Int";
					format = "####";
				}else{
					if(Number(dataLength) > 200){
						width = "150";
					}else if(Number(dataLength) > 50 ){
						width = "120";
					}else if(Number(dataLength) < 6){
						width = "80";
					}
				}


				titleSpace = "";
				for(var j=0; j < (41 - stringByteLength(title)); j++){
					titleSpace += " ";
				}
				typeTab = type == "Int" ? "\t\t\t" : type == "CheckBox"? "\t":"\t\t";

				saveNameTab = "";
				for(var j=0; j < (4 - Math.trunc(colnm2.length / 4)); j++){
					saveNameTab += "\t";
				}
				query += '{Header:"'+title+'", Type:"Text", Hidden:0, Width:100, Align:"Center", SaveName:"'+colnm+'", KeyField:0, Format:"", UpdateEdit:1, InsertEdit:1 },'+en;
				formatTab = "";
				for(var j=0; j < (3 - Math.trunc((format.length + 1) / 4)); j++){
					formatTab += "\t";
				}

				query += '{Header:"'+title+'",' + titleSpace + '\tType:"'+type+'",' + typeTab + 'Hidden:0,\tWidth:' + width + ',\tAlign:"Center",\tSaveName:"'+colnm2+'",' + saveNameTab + 'KeyField:' + keyField + ',\tFormat:"'+format+'",' + formatTab + 'UpdateEdit:' + updateEdit + ',\tInsertEdit:1,\tEditLen:'+dataLength;
				if(type == "CheckBox"){
					query += ',\tTrueValue:"Y",\tFalseValue:"N"';
				}
				query += '},'+en;

			}

			$("#initSheet").html(query);

	  	}catch(ex){alert("makeInitSheet() Error : " + ex);}

	}


</script>
<style type="text/css">
*{font-size:12px;}
input[type="text"] { padding:2px; border:1px solid #b1b1b1;}
.table {width:100%;height:100%;table-layout: fixed;}
.table textarea { width:100%;height:100%;  line-height:18px;}
.table td {vertical-align: top;border-right:10px solid #ffffff;border-bottom:10px solid #ffffff;}
.table th {font-weight: bold; text-align: left; height:30px;border-right:10px solid #ffffff;}
.tableList th, .tableList td {border:0px;}
textarea {font-family: verdana;}
.IBMain,.IBMain *{font-size:11px;}
.IBType{padding:3px 5px 3px 5px;}
</style>
</head>
<body class="bodywrap">
<div class="wrapper">
	<form id="sheet1Form" name="sheet1Form" >
	<input type="hidden" id="srchUseYn" name="srchUseYn" value="Y" />
	<input type="hidden" id="fileSeq" name="fileSeq"/>
	<!-- 조회조건 -->
	<div class="sheet_search outer">
		<table>
		<tr>
			<td style="width:180px;">
				<span>테이블명</span>
				<input type="text" id="searchTable" name="searchTable" class="text" value=""/>
			</td>
			<td>
				※ <label style="color:blue;font-weight: bold;line-height: 22px;">IntelliJ</label>에서 붙여넣기 시 Tab 유지 안될 경우 설정<br/>
				<b>Settings > Editor > General > Smart Keys : "Reformat on paste" : <label style="color:red;">[Indent block]</label> </b>
			</td>
			<td>
				<a href="javascript:doAction1('Search')" class="button">조회</a>
			</td>
		</tr>
		</table>
	</div>
	</form>


	<div style="position: absolute; top:54px; left:10px; right:10px; bottom:0px; ">

	    <!-- 시트의 부모 요소 -->
	    <div style="position: absolute; top:0px; left:0px; width:500px; bottom:0px; ">
			<div class="h10 inner"></div>
	        <!-- 시트가 될 DIV 객체 -->
	        <script type="text/javascript"> createIBSheet("sheet1", "100%", "100%", "${ssnLocaleCd}"); </script>
	    </div>

	    <div style="position: absolute; top:10px; left:520px; right:0px; bottom:0px; ">
			<table class="table">
			<colgroup>
				<col width="30%" />
				<col width="25%" />
				<col width="" />
			</colgroup>
			<tr>
				<th>COLUMN List</th>
				<th>SELECT Query</th>
				<th>MERGE Query</th>
			</tr>
			<tr>
				<td>
					<div id="colList" style="height:100%;overflow: auto; border:1px solid #b1b1b1;"></div>
				</td>
				<td>
					<textarea id="selectQry" name="selectQry" rows="3"></textarea>
				</td>
				<td>
					<textarea id="mergeQry" name="mergeQry" rows="3"></textarea>
				</td>
			</tr>
			<tr>
				<th colspan="3">DELETE Query</th>
			</tr>
			<tr>
				<td colspan="3" style="height:100px;">
					<textarea id="deleteQry" name="deleteQry" rows="2"></textarea>
				</td>
			</tr>
			</table>
	    </div>
	</div>

</div>
</body>
</html>



/*
<?xml version="1.0" encoding="UTF-8"?>-->
<!--<!DOCTYPE mapper-->
<!--		PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"-->
<!--		"http://mybatis.org/dtd/mybatis-3-mapper.dtd">-->
<!--	<mapper namespace="sys.system.creQueryMgr">-->

<!--		<select parameterType="map" resultType="cMap" id="getCreQueryMgrList">-->

<!--				<![CDATA[-->
<!--					SELECT A.COLUMN_NAME, B.POSITION, DECODE(B.POSITION, null, 'N', 'Y') AS PK_YN-->
<!--					    , REPLACE(SUBSTR(INITCAP('a'||LOWER(A.COLUMN_NAME)), 2),'_', '') AS COLUMN_NAME2-->
<!--					    , C.COMMENTS-->
<!--                        , A.DATA_TYPE || DECODE(A.DATA_TYPE, 'VARCHAR2','('||A.DATA_LENGTH||')', '') AS DATA_TYPE-->
<!--					 FROM DBA_TAB_COLUMNS A-->
<!--					    , (SELECT Y.OWNER, Y.COLUMN_NAME, Y.POSITION-->
<!--					         FROM DBA_CONSTRAINTS X, DBA_CONS_COLUMNS Y-->
<!--					        WHERE X.TABLE_NAME = TRIM(#{searchTable})-->
<!--					          AND X.CONSTRAINT_TYPE = 'P'-->
<!--					          AND X.OWNER = Y.OWNER-->
<!--					          AND X.CONSTRAINT_NAME = Y.CONSTRAINT_NAME -->
<!--					      ) B-->
<!--					    , ALL_COL_COMMENTS C  -->
<!--					WHERE A.OWNER       = DECODE(F_COM_GET_STD_CD_VALUE(TRIM(#{ssnEnterCd}),'SYS_DB_OWNER'),NULL,USER,F_COM_GET_STD_CD_VALUE(TRIM(#{ssnEnterCd}),'SYS_DB_OWNER'))-->
<!--					  AND A.TABLE_NAME  = UPPER(TRIM(#{searchTable}))-->
<!--					  AND A.OWNER       = B.OWNER(+)-->
<!--					  AND A.COLUMN_NAME = B.COLUMN_NAME(+)-->
<!--				      AND A.OWNER       = C.OWNER(+)-->
<!--				      AND A.TABLE_NAME  = C.TABLE_NAME(+)-->
<!--				      AND A.COLUMN_NAME = C.COLUMN_NAME(+)-->
<!--					  AND A.COLUMN_NAME NOT IN ('ENTER_CD','CHKDATE','CHKID')-->
<!--					ORDER BY NVL(B.POSITION, 9), A.COLUMN_ID	-->
<!--				]]>-->


<!--		</select>-->


<!--</mapper>
*/




