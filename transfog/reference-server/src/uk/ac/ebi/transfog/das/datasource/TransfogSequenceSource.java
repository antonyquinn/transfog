/*
 * Copyright 2005 European Bioinformatics Institute.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
*/

package uk.ac.ebi.transfog.das.datasource;

import org.biojava.servlets.dazzle.datasource.*;
import org.biojava.servlets.dazzle.holder.StreamMonitorHolder;
import org.biojava.servlets.dazzle.holder.StreamMonitorHolderImpl;

import org.biojava.bio.seq.*;

import javax.servlet.ServletContext;
import java.util.*;

/**
 * DAS reference server serving sequence (but no features) for IPI accession numbers
 * and Ensembl gene accession identifiers.
 * <p>
 * The following dazzlecfg.xml settings can be overriden by servlet context parameters:
 * </p>
 * <pre>
 *  transfog-seq-url
 * </pre>
 *
 * @author  Antony Quinn
 * @version $Id: TransfogSequenceSource.java,v 1.2 2005/05/07 18:59:48 aquinn Exp $
 * @since   1.5
 */
public class TransfogSequenceSource
       extends AbstractDataSource
       implements DazzleReferenceSource, StreamMonitorHolder {

    // Datasource descriptors
    private static final String DATA_SOURCE_TYPE    = "TransfogSequenceSource";
    private static final String DATA_SOURCE_VERSION = "1.0";

    // Identifier prefixes
    private static final String PREFIX_SEP          = ",";

    // Wrapped classes
    private final ProxyReferenceSource proteinProxy     = new ProxyReferenceSource();
    private final ProxyReferenceSource geneProxy        = new ProxyReferenceSource();

    // Gene and protein prefixes
    private Set genePrefixSet    = null;
    private Set proteinPrefixSet = null;

    // Gene and protein prefixes (properties)
    private String genePrefixes     = "ENSG";
    private String proteinPrefixes  = "IPI";

    private StreamMonitorHolder streamMonitorHolder = new StreamMonitorHolderImpl();
    private int maxCachedFeatures = 500;

    /**
     * Set up connections to proxy servers
     *
     * @param   servletContext      Servlet context
     * @throws  org.biojava.servlets.dazzle.datasource.DataSourceException if could not initialise proxy servers
     * @see     org.biojava.servlets.dazzle.datasource.ProxyReferenceSource#init(javax.servlet.ServletContext)
     */
    public void init(ServletContext servletContext) throws DataSourceException {
        // Initialise abstract parent
        super.init(servletContext);
        // Gene and protein prefixes
        genePrefixSet    = getPrefixSet(getGenePrefixes());
        proteinPrefixSet = getPrefixSet(getProteinPrefixes());
        // Protein proxy server (for protein sequence and features)
        proteinProxy.setMaxCachedFeatures(getMaxCachedFeatures());
        proteinProxy.setRefreshInterval(getRefreshInterval());
        proteinProxy.init(servletContext);
        // Gene proxy server (for gene sequence and features)
        geneProxy.setMaxCachedFeatures(getMaxCachedFeatures());
        geneProxy.setRefreshInterval(getRefreshInterval());
        geneProxy.init(servletContext);
    }

    /* Class-specific properties */

    public String getGenePrefixes()    {
        return genePrefixes;
    }

    public void setGenePrefixes(String genePrefixes)    {
        this.genePrefixes = genePrefixes;
    }

    public String getProteinPrefixes()    {
        return proteinPrefixes;
    }

    public void setProteinPrefixes(String proteinPrefixes)    {
        this.proteinPrefixes = proteinPrefixes;
    }

    public String getGeneUrl() {
        return geneProxy.getRemoteReferenceSource();
    }

    public void setGeneUrl(String url) {
        geneProxy.setRemoteReferenceSource(url);
    }

    public String getProteinUrl() {
        return proteinProxy.getRemoteReferenceSource();
    }

    public void setProteinUrl(String url) {
        proteinProxy.setRemoteReferenceSource(url);
    }

    /* TODO: make an interface from the following */

    public int getMaxCachedFeatures() {
        return maxCachedFeatures;
    }

    public void setMaxCachedFeatures(int i) {
        this.maxCachedFeatures = i;
    }

    /* StreamMonitorHolder interface */

    public int getRefreshInterval() {
        return streamMonitorHolder.getRefreshInterval();
    }

    public void setRefreshInterval(int i) {
        streamMonitorHolder.setRefreshInterval(i);
    }

   /* DazzleReferenceSource interface */

    public Set getEntryPoints() {
        return Collections.unmodifiableSet(Collections.EMPTY_SET);
    }

    public FeatureHolder getFeatures(String id) throws DataSourceException, NoSuchElementException {
        if (isGeneId(id))   {
            return geneProxy.getFeatures(id);
        }
        if (isProteinId(id))   {
            // TODO: uncomment "xff" line in BioJava.FeatureFetcher (had to do special build because UniProt DAS can't handle XFF)
            return proteinProxy.getFeatures(id);
        }
        return null;
    }

    public String getMapMaster()    {
        return null;
    }

    /**
     * Returns nucleotide or amino acid sequence for a given gene or protein identifier
     *
     * @param   id                       Gene or protein identifier
     * @return  Nucleotide or amino acid sequence
     * @throws  org.biojava.servlets.dazzle.datasource.DataSourceException      if could not get sequence from proxy server or if unrecognised ID
     * @throws  java.util.NoSuchElementException   if gene or protein ID does not exist
     * @see     org.biojava.servlets.dazzle.datasource.ProxyReferenceSource#getSequence(String)
     */
    public Sequence getSequence(String id) throws DataSourceException, NoSuchElementException {
        if (isGeneId(id))   {
            return geneProxy.getSequence(id);
        }
        if (isProteinId(id))   {
            return proteinProxy.getSequence(id);
        }
        String message = "Not a recognised gene or protein identifier: " + id;
        message += " [recognised prefixes: gene=" + getGenePrefixes();
        message += " protein=" + getProteinPrefixes() + "]";
        throw new DataSourceException(message);
    }

    /* DazzleDataSource interface */

    public Set getAllTypes() {
       return Collections.unmodifiableSet(Collections.EMPTY_SET);
    }

    public String getDataSourceType()    {
        return DATA_SOURCE_TYPE;
    }

    public String getDataSourceVersion() {
        return DATA_SOURCE_VERSION;
    }

    public String getLandmarkVersion(String ref) throws DataSourceException, NoSuchElementException {
        return "default";
    }

    /* Private methods */

    private boolean isGeneId(String id)   {
        return hasPrefix(id, genePrefixSet);
    }

    private boolean isProteinId(String id)   {
        return hasPrefix(id, proteinPrefixSet);
    }

    private boolean hasPrefix(String id, Set prefixSet) {
        for (Iterator i = prefixSet.iterator(); i.hasNext();)    {
            String prefix = (String) i.next();
            if (id.startsWith(prefix))  {
                return true;
            }
        }
        return false;
    }

    private Set getPrefixSet(String prefixes)    {
        StringTokenizer tokenizer = new StringTokenizer(prefixes, PREFIX_SEP);
        Set prefixSet = new HashSet(tokenizer.countTokens());
        while (tokenizer.hasMoreTokens())   {
            String prefix = tokenizer.nextToken();
            prefixSet.add(prefix);
        }
        return prefixSet;
    }

}