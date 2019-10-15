<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:functx="http://www.functx.com"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xpath-default-namespace="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
    version="2.0">

    <xsl:include href="functx-1.0-doc-2007-01.xsl"/>


    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <xsl:variable name="documents"
        select="collection('../exporteren/Exports/UBU000005064_png/UBU000005064_png_duplicaat/page')"/>

    <xsl:template match="/">
        <Root>
            <Comment>Total number of documents: <xsl:value-of select="count($documents)"/></Comment>
            <xsl:text disable-output-escaping="yes">
               &lt;Law start-page="0"
        start-region="0"
        rel-size="0"
        keyword="0"  
        title-prefix="Mock title that does not exist" &gt; </xsl:text>
            <!-- Go over the pages in the right order and apply templates-->
            <xsl:for-each select="$documents">
                <xsl:sort select="base-uri()"/>
                <xsl:variable name="page"
                    select="number(replace(replace(base-uri(),'file:/([^/]+/)*',''),'.xml',''))"/>
                <xsl:if test="$page&gt;10 and $page&lt;339">
                    <!-- Ugly way to skip first and last bit of the book-->
                    <xsl:apply-templates select="/PcGts/Page"/>
                </xsl:if>
            </xsl:for-each>
            <xsl:text disable-output-escaping="yes">        &lt;/Law&gt;</xsl:text>
        </Root>
    </xsl:template>

    <xsl:template match="Page">
        <xsl:variable name="PageElement" select="."/>
        <!-- Reading order tends to be incorrect at times, so first assert proper reading order:
            * Determine coordinates of the left upper corner of each text region. 
            * Determine column: 
                .00-.33 of pagewidth > column 1
                .33-.66 of pagewidth > column 2
                else                 > column 3 (should never occur)   
            * Determine vertical position (vpos = y value)
            * Save column and vpos together with region identifier 
            This goes well most of the time, at least when page indeed has columns -->

        <xsl:variable name="regionsWithLocations">
            <xsl:for-each select="ReadingOrder/OrderedGroup/RegionRefIndexed">
                <xsl:variable name="regionRef" select="./@regionRef"/>
                <xsl:variable name="coords"
                    select="$PageElement/TextRegion[@id=$regionRef]/Coords/@points"/>
                <xsl:variable name="x" select="number(substring-before($coords,','))"/>
                <xsl:variable name="column">
                    <xsl:choose>
                        <xsl:when test="$x &lt; $PageElement/@imageWidth div 3">1</xsl:when>
                        <xsl:when test="$x &lt; 2 * $PageElement/@imageWidth div 3">2</xsl:when>
                        <xsl:otherwise>3</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="y"
                    select="number(substring-after(substring-before($coords,' '),','))"/>

                <xsl:element name="myRegionRef">
                    <xsl:attribute name="column" select="$column"/>
                    <xsl:attribute name="vpos" select="$y"/>
                    <xsl:attribute name="regionRef" select="$regionRef"/>
                </xsl:element>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- Iterate over text regions ordered by column and vpos -->
        <xsl:for-each select="$regionsWithLocations/*">
            <xsl:sort select="@column"/>
            <xsl:sort select="@vpos" data-type="number"/>
            <xsl:variable name="regionRef" select="./@regionRef"/>
            <xsl:apply-templates select="$PageElement/TextRegion[@id=$regionRef]"/>
        </xsl:for-each>
       
    </xsl:template>


    <xsl:template match="TextRegion">               
        <!-- Check if this text region marks the start of a new law -->
        <xsl:choose>
            <!-- Check if first line is the page header (then look at second line)-->
            <xsl:when
                test="./TextLine[1]/TextEquiv/Unicode[matches(., 'Groot\s+Gelders|Placaet\s*-\s*Boeck')]">
                <xsl:apply-templates select="./TextLine[2]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="./TextLine[1]"/>
            </xsl:otherwise>
        </xsl:choose>
       
        <xsl:variable name="avgFontSize">
            <xsl:choose>
                <xsl:when test="count(./TextLine/TextStyle)&gt;0">
                    <xsl:value-of
                        select="sum(./TextLine/TextStyle/@fontSize) div count(./TextLine/TextStyle)"
                    />
                </xsl:when>
                <xsl:otherwise>-1</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <MyTextRegion id="{@id}" 
            nLines="{count(./TextLine)}"
            nItalic="{count(./TextLine/TextStyle[@italic='true'])}" 
            nBold="{count(./TextLine/TextStyle[@bold='true'])}"
            avgFontSize="{$avgFontSize}" 
            page="{replace(replace(base-uri(),'file:/([^/]+/)*',''),'.xml','')}">
            <xsl:value-of select="./TextEquiv/Unicode/."/>
        </MyTextRegion>

        <!--<xsl:apply-templates select="./TextLine[last()]"/> In case I wanna do something with the last line too-->

    </xsl:template>


    <xsl:template match="TextLine" name="is-title-law">
        <!-- Determine whether this line marks the start of a new law -->

        <xsl:variable name="avgFontSize" select="8.5"/>
        <!-- Font size throughout the document (running text) -->

        <xsl:variable name="txt" select="./TextEquiv/Unicode/."/>
        <xsl:variable name="nwords" select="count(tokenize($txt, '\s+'))"/>
        <xsl:variable name="length" select="max((count(tokenize($txt, '\s+')),4)) div 3"/>
        <!-- At least three (?) words (alphabetical?) on line -->


        <!-- Hard: Has more than 15 alphabetical characters? (To prevent eventual page numbers/ page headers etc. to be taken into account)-->


        <!-- Soft: Regex for detecting start of law based on keyword (at start of line)-->
        <xsl:variable name="keyword"
            select="matches($txt, '^(((Provin?sionele|N[it]euwe|Nadere)\s+)?((Echt|Kercken)-?\s?)?([Rr][eo]sol[ua][ts]ien?|[Pp]lace?aet(en)?|[Oo]rdonnantie|[Pp]ub(li?|h)catie|[Ww]aerschouwi?ngh?e?|[Oo]rde?n[iu]ngh?e?|[Aa]mp(li|h)atie|[Rr]egelement|[Oo]rdre|[Vv]erbo[dt]t?))')"/>

        <xsl:variable name="keywordContra" select="matches($txt, '^(Den|Extract|DEEE)')"/>
        <xsl:variable name="Capital" select="matches($txt, '^[A-Z]')"/>

        <xsl:variable name="size">
            <!-- relative size -->
            <xsl:choose>
                <xsl:when test="TextStyle/@fontSize">
                    <xsl:value-of select="TextStyle/@fontSize div $avgFontSize"/>
                </xsl:when>
                <xsl:otherwise>1.1</xsl:otherwise>
                <!-- Textstyle (incl. fontSize) is not always available. In that case, assume that it might be bigger than average -->
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="italic">
            <xsl:choose>
                <xsl:when test="TextStyle/@italic">1.1</xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="bold">
            <xsl:choose>
                <xsl:when test="TextStyle/@bold">1.1</xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="page"
            select="replace(replace(base-uri(),'file:/([^/]+/)*',''),'.xml','')"/>
        <xsl:variable name="region" select="../@id"/>

        <!--  How to output xml tags as text? Close prvious tag and then open a new one <xsl:value-of select="&lt; /Law"/> -->

      
            <xsl:if test="($nwords &gt;2 and $keyword and $Capital) or ($size &gt; 1.2 and $nwords &gt; 2 and not($keywordContra) and $Capital)">
              
               <!-- Insert end-tag for previous law and start-tag for new law (this is ugly code!) --> 
                <xsl:text disable-output-escaping="yes">
               &lt;/Law &gt;
               &lt;Law </xsl:text>
                start-page="<xsl:value-of select="$page"/>"
                start-region="<xsl:value-of select="$region"/>"
                rel-size="<xsl:value-of select="$size"/>"
                keyword="<xsl:value-of select="$keyword"/>"
                title-prefix="<xsl:value-of select="$txt"/>"
                <xsl:text disable-output-escaping="yes">&gt;</xsl:text>

            </xsl:if>

        
    </xsl:template>

</xsl:stylesheet>
