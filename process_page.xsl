<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:functx="http://www.functx.com"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:num="http://whatever"
    xpath-default-namespace="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
    version="2.0">

    <xsl:include href="functx-1.0-doc-2007-01.xsl"/>


    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <xsl:variable name="documents"
        select="collection('../exporteren/Exports/UBU000005064_png/UBU000005064_png_duplicaat/page')"/>

    <xsl:template match="/">
        <Root>
            <Comment>Total number of documents: <xsl:value-of select="count($documents)"/></Comment>
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
        </Root>
    </xsl:template>


    <xsl:template match="Metadata">
        <Comment>There is metadata </Comment>
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
            * Save column and vpos together with region identifier -->

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
            <!-- 
            Node: <xsl:value-of select="@regionRef"/>
            column: <xsl:value-of select="@column"/>
            vpos: <xsl:value-of select="@vpos"/>
             -->

            <xsl:apply-templates select="$PageElement/TextRegion[@id=$regionRef]"/>

        </xsl:for-each>

    </xsl:template>

    <xsl:template match="TextRegion">
        <xsl:variable name="txt" select="./TextEquiv/Unicode/."/>
        <xsl:variable name="page"
            select="replace(replace(base-uri(),'file:/([^/]+/)*',''),'.xml','')"/>

        <xsl:variable name="headerness"/>
        
        <xsl:choose> <!-- Check if page header (then look at second line)-->
            <xsl:when test="./TextLine[1]/TextEquiv/Unicode[matches(., 'Groot\s+Gelders|Placaet\s*-\s*Boeck')]">  
                <xsl:apply-templates select="./TextLine[2]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="./TextLine[1]"/>
            </xsl:otherwise>
            
        </xsl:choose>
        
        
        <!--<xsl:apply-templates select="./TextLine[last()]"/>-->
 


        <xsl:variable name="l1" select="tokenize($txt,'\S+\n')[1]"/>
        <!-- l1= <xsl:value-of select="$l1"/> -->
        <xsl:variable name="rest" select="substring-after($txt,'\S+\n')"/>
        <!-- rest=<xsl:value-of select="$rest"/> -->
        <xsl:choose>
            <xsl:when test="$l1[matches(., 'Groot\s+Gelders|Placaet\s*-\s*Boeck')]">
                <!-- Us first line as header, if there is a rest: continue processing -->
<!--                <Header page="{$page}">Just a header (<xsl:value-of select="$l1"/>) </Header>-->
                <xsl:call-template name="createTextRegion">
                    <xsl:with-param name="text" select="$rest"/>
                    <xsl:with-param name="page" select="$page"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="createTextRegion">
                    <xsl:with-param name="text" select="$txt"/>
                    <xsl:with-param name="page" select="$page"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="TextLine" name="is-title-law">
        <!-- Ignore the content of lines and words, the content is already included in the textequivalent of the entire region -->
        <!-- Or not: Textline SOMETIMES includes information on font size! <TextStyle fontFamily="Times New Roman" fontSize="9.0"/> -->
        <!-- Determine 'headerness'-->


        <xsl:variable name="avgFontSize" select="8.5"/> <!-- Font size throughout the document (running text) -->

        <xsl:variable name="txt" select="./TextEquiv/Unicode/."/>
        
        
        
        
        <xsl:variable name="nwords" select="count(tokenize($txt, '\s+'))"/>  
        <xsl:variable name="length" select="max((count(tokenize($txt, '\s+')),4)) div 3"/>  <!-- At least three (?) words (alphabetical?) on line -->
        

        <!-- Hard: Has more than 15 alphabetical characters? (To prevent eventual page numbers/ page headers etc. to be taken into account)-->

        
        <!-- Soft: Regex for detecting start of law based on keyword (at start of line)-->
        <xsl:variable name="keyword" select="matches($txt, '^(((Provin?sionele|N[it]euwe|Nadere)\s+)?((Echt|Kercken)-?\s?)?([Rr][eo]sol[ua][ts]ien?|[Pp]lace?aet(en)?|[Oo]rdonnantie|[Pp]ub(li?|h)catie|[Ww]aerschouwi?ngh?e?|[Oo]rde?n[iu]ngh?e?|[Aa]mp(li|h)atie|[Rr]egelement|[Oo]rdre|[Vv]erbo[dt]t?))')"/>
        
        <xsl:variable name="keywordContra" select="matches($txt, '^(Den|Extract)')"/>
        <xsl:variable name="Capital" select="matches($txt, '^[A-Z]')"/>

        <xsl:variable name="size"><!-- relative size -->
            <xsl:choose>
                <xsl:when test="TextStyle/@fontSize">
                    <xsl:value-of select="TextStyle/@fontSize div $avgFontSize"/>
                </xsl:when>
               <xsl:otherwise>1.1</xsl:otherwise> <!-- Assume that it might be bigger than average -->
            </xsl:choose>
        </xsl:variable>
            
        <xsl:variable name="italic"><xsl:choose><xsl:when test= "TextStyle/@italic">1.1</xsl:when><xsl:otherwise>1</xsl:otherwise></xsl:choose></xsl:variable>

        <xsl:variable name="bold"><xsl:choose><xsl:when test= "TextStyle/@bold">1.1</xsl:when><xsl:otherwise>1</xsl:otherwise></xsl:choose></xsl:variable>
        
      
        <xsl:variable name="score" select="$size * $length * $italic * $bold"/>
       <!-- Score: <xsl:value-of select="$score"/> -->
        
        <xsl:variable name="page" select="replace(replace(base-uri(),'file:/([^/]+/)*',''),'.xml','')"/>

        <xsl:choose>
            <xsl:when test="$nwords &gt;2 and $keyword and $Capital">               
                <Header type='start-law' page="{$page}" size="{$size}" ><xsl:value-of select="$txt"/></Header>                
            </xsl:when>
                       
            <xsl:when test="$size &gt; 1.2 and $nwords &gt; 2 and not($keywordContra) and $Capital"> 
                <Header type='start-law-2' page="{$page}" size="{$size}"><xsl:value-of select="$txt"/></Header>                
            </xsl:when> 
            
        </xsl:choose>
        

    </xsl:template>


    <xsl:template name="sanitize-text">
        <xsl:param name="text"/>
        <!--
        in $fr, define a sequence of regexs to be replaced
        in $to, define the replacements
        Here: 
        * remove hyphen followed by line break
        * replace linebreak with space when last line did not end with period
        * replace linebreak with space when last ended with period but new line does not start with capital 
        -->
        <xsl:variable name="fr" select="('[¬-]\s*&#10;', '([^.!?])&#10;', '([.!?])&#10;([a-z])')"/>
        <xsl:variable name="to" select="('', '$1 ', '$1 $2')"/>
        <xsl:value-of select="functx:replace-multi($text, $fr, $to)"/>
    </xsl:template>


    <xsl:template name="createTextRegion">
        <xsl:param name="text"/>
        <xsl:param name="page"/>

        <!--<xsl:variable name="nLines" select="count(./TextLine)"/>
        <xsl:variable name="nItalic" select="count(./TextLine/TextStyle[@italic='true'])"/>
        <xsl:variable name="nBold" select="count(./TextLine/TextStyle[@bold='true'])"/>
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

        <MyTextRegion nLines="{$nLines}" nItalic="{$nItalic}" nBold="{$nBold}"
            avgFontSize="{$avgFontSize}" page="{$page}">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="$text"/>
            </xsl:call-template>
        </MyTextRegion>-->

    </xsl:template>


    <xsl:function name="num:roman" as="xs:integer">
        <xsl:param name="r" as="xs:string"/>
        <xsl:param name="s"/>
        <xsl:choose>
            <xsl:when test="ends-with($r,'CM')">
                <xsl:sequence select="900 + num:roman(substring($r,1,string-length($r)-2), 900)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'M')">
                <xsl:sequence select="1000+ num:roman(substring($r,1,string-length($r)-1), 1000)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'CD')">
                <xsl:sequence select="400+ num:roman(substring($r,1,string-length($r)-2), 400)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'D')">
                <xsl:sequence select="500+ num:roman(substring($r,1,string-length($r)-1), 500)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'XC')">
                <xsl:sequence select="90+ num:roman(substring($r,1,string-length($r)-2), 90)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'C')">
                <xsl:sequence
                    select="(if(100 ge number($s)) then 100 else -100)+ num:roman(substring($r,1,string-length($r)-1), 100)"
                />
            </xsl:when>
            <xsl:when test="ends-with($r,'XL')">
                <xsl:sequence select="40+ num:roman(substring($r,1,string-length($r)-2), 40)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'L')">
                <xsl:sequence select="50+ num:roman(substring($r,1,string-length($r)-1), 50)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'IX')">
                <xsl:sequence select="9+ num:roman(substring($r,1,string-length($r)-2), 9)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'X')">
                <xsl:sequence
                    select="(if(10 ge number($s)) then 10 else -10) + num:roman(substring($r,1,string-length($r)-1), 10)"
                />
            </xsl:when>
            <xsl:when test="ends-with($r,'IV')">
                <xsl:sequence select="4+ num:roman(substring($r,1,string-length($r)-2), 4)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'V')">
                <xsl:sequence select="5+ num:roman(substring($r,1,string-length($r)-1), 5)"/>
            </xsl:when>
            <xsl:when test="ends-with($r,'I')">
                <xsl:sequence
                    select="(if(1 ge number($s)) then 1 else -1)+ num:roman(substring($r,1,string-length($r)-1), 1)"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="0"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
