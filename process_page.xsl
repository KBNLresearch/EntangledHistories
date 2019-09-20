<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:functx="http://www.functx.com"
    xpath-default-namespace="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
    version="2.0">

    <xsl:include href="functx-1.0-doc-2007-01.xsl"/>


    <xsl:output method="xml" encoding="UTF-8"/>
    
    <xsl:variable name="documents" select="collection('../exporteren/Exports/UBU000005064_png/UBU000005064_png/page')"/>
    
    


    <xsl:template match="/"> 
        <Root> 
        <Comment>Total number of documents: <xsl:value-of select="count($documents)"/></Comment>
        <!-- Go over the pages in the right order and apply templates-->
        <xsl:for-each select="$documents">
            <xsl:sort select="base-uri()"></xsl:sort>
        <xsl:apply-templates/> 
        </xsl:for-each> 
        </Root>
    </xsl:template>
   

<xsl:template match="Metadata"> <Comment>There is metadata </Comment></xsl:template>


    <xsl:template match="Page/ReadingOrder"> <Comment>Reading order is defined here </Comment></xsl:template>

    <xsl:template match="Page/TextRegion">
        <xsl:variable name="txt" select="./TextEquiv/Unicode/."/>
        <xsl:variable name="page" select="replace(replace(base-uri(),'file:/([^/]+/)*',''),'.xml','')"/>

        <xsl:choose>
            <xsl:when test="$txt[matches(., 'Groot Gelders')]"> Just a header (<xsl:value-of
                    select="$txt"/>) </xsl:when>

            <xsl:otherwise>
                <xsl:variable name="newtext">
                    <xsl:call-template name="sanitize-text">
                        <xsl:with-param name="text" select="./TextEquiv/Unicode/."/>
                    </xsl:call-template>
                </xsl:variable>  
            
                
                <xsl:variable name="nLines" select="count(./TextLine)"/>
                <xsl:variable name="nItalic" select="count(./TextLine/TextStyle[@italic='true'])"/>
                <xsl:variable name="nBold" select="count(./TextLine/TextStyle[@bold='true'])"/>
                <xsl:variable name="avgFontSize">
                    <xsl:choose>
                        <xsl:when test="count(./TextLine/TextStyle)&gt;0"><xsl:value-of select="sum(./TextLine/TextStyle/@fontSize) div count(./TextLine/TextStyle)"/></xsl:when>
                        <!--<TextStyle fontFamily="Times New Roman" fontSize="9.5" bold="true" italic="true"/>
                        Seems to be defined only when OCR is used (e.g. KBNL03000092135_png), not for HTR-trained text..
                        -->
                        <xsl:otherwise>-1</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                
                    
                          
                
                <!--<xsl:if test="$size&gt;10">HEADER</xsl:if>-->
                
                
                <MyTextRegion nLines="{$nLines}" nItalic="{$nItalic}" nBold="{$nBold}" avgFontSize="{$avgFontSize}" page="{$page}"><xsl:value-of select="$newtext"/></MyTextRegion>
                
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>


    <xsl:template match="TextLine">
        <!-- Ignore the content of lines and words, the content is already included in the textequivalent of the entire region -->
        <!-- Or not: Textline SOMETIMES includes information on font size! <TextStyle fontFamily="Times New Roman" fontSize="9.0"/> -->
    </xsl:template>
  

    <xsl:template name="sanitize-text">
        <xsl:param name="text"/>
        
        <!--
        in $fr, define a sequence of regexs to be replaced
        in $to, define the replacements
        Here: * remove hyphen followed by line break
        * replace linebreak with space when last line did not end with period
        * replace linebreak with space when last ended with period but new line does not start with capital 
        --> 
        <xsl:variable name="fr" select="('[¬-]\s*&#10;', '([^.!?])&#10;', '([.!?])&#10;([a-z])')"/>
        <xsl:variable name="to" select="('', '$1 ', '$1 $2')"/>
        <xsl:variable name="newtext" select="functx:replace-multi($text, $fr, $to)"/>
        <xsl:value-of select="$newtext"/>
    </xsl:template>


    <xsl:template name="string-replace-all">
        <xsl:param name="text"/>
        <xsl:param name="replace"/>
        <xsl:param name="by"/>
        <xsl:choose>
            <xsl:when test="$text = '' or $replace = '' or not($replace)">
                <!-- Prevent this routine from hanging -->
                <xsl:value-of select="$text"/>
            </xsl:when>
            <xsl:when test="contains($text, $replace)">
                <xsl:value-of select="substring-before($text, $replace)"/>
                <xsl:value-of select="$by"/>
                <xsl:call-template name="string-replace-all">
                    <xsl:with-param name="text" select="substring-after($text, $replace)"/>
                    <xsl:with-param name="replace" select="$replace"/>
                    <xsl:with-param name="by" select="$by"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


</xsl:stylesheet>
