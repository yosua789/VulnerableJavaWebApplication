<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html"/>
  <xsl:template match="/">
    <html>
      <head><title>SpotBugs Report</title></head>
      <body>
        <h1>SpotBugs Findings</h1>
        <table border="1">
          <tr><th>Type</th><th>Class</th><th>Method</th><th>Message</th></tr>
          <xsl:for-each select="BugCollection/BugInstance">
            <tr>
              <td><xsl:value-of select="@type"/></td>
              <td><xsl:value-of select="Class/@classname"/></td>
              <td><xsl:value-of select="Method/@name"/></td>
              <td><xsl:value-of select="LongMessage"/></td>
            </tr>
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
