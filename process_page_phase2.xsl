<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:functx="http://www.functx.com"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:num="http://whatever" version="2.0">


    <xsl:include href="functx-1.0-doc-2007-01.xsl"/>


    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <Root>
        <xsl:apply-templates/>
        </Root>
    </xsl:template>
    <xsl:template match="Comment"/>

    <xsl:template match="Law">

        <xsl:variable name="years">
            <xsl:for-each select="MyTextRegion">
            <xsl:analyze-string regex="(\b\d{{4}}\b)|(\b[Mm][MmCcDdLlXxVvIi1]{{2,}}\b)" select="." flags='!i'>
                <xsl:matching-substring>
                    <Year><xsl:value-of select="."/></Year>
                </xsl:matching-substring>
            </xsl:analyze-string>
            </xsl:for-each>
        </xsl:variable>
   
        <xsl:copy>
            <xsl:attribute name="years" select="string-join($years/Year,',')"/>          
            <xsl:copy-of select="@*"/>
            
            <!-- Paste all text regions together separated by line feeds (&#10;), then process through sanitize-text to remove hyphenation etc.-->            
            <xsl:value-of select="num:sanitize-text(string-join(MyTextRegion/., '&#10;'))"/>
        </xsl:copy>
    </xsl:template>

    <xsl:function name="num:sanitize-text">
        <xsl:param name="text"/>       
        <!--
        in $fr, define a sequence of regexs to be replaced
        in $to, define the replacements
        Here: 
        * remove hyphen followed by line break
        * replace linebreak with space when last line did not end with period
        * replace linebreak with space when last ended with period but new line does not start with capital 
        -->
        <xsl:variable name="fr" select="('[¬-]\s*&#10;', '([^.!?])\s*&#10;', '([.!?])\s*&#10;([a-z])')"/>
        <xsl:variable name="to" select="('', '$1 ', '$1 $2')"/>
        <xsl:value-of select="functx:replace-multi($text, $fr, $to)"/>
    </xsl:function>

 
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
