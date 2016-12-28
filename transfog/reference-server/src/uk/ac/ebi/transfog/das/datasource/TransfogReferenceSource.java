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
import org.biojava.servlets.dazzle.holder.SequenceResourceHolder;

import org.biojava.bio.seq.*;

import javax.servlet.ServletContext;
import java.util.*;

import uk.ac.ebi.dogwood.datasource.GFFOntologySource;
import uk.ac.ebi.dogwood.datasource.GFFOntologyReferenceSource;

/**
 * DAS reference server with the TRANSFOG candidate list of genes as entry points.
 * Entry points are read from a GFF file containing IPI accession numbers and/or Ensembl gene accession identifiers.
 * The GFF file also contains a rank and notes explaining the ranking for that gene/protein.
 * <p>
 * The following dazzlecfg.xml settings can be overriden by servlet context parameters:
 * <pre>
 *  transfog-ref-url
 *  transfog-ref-username
 *  transfog-ref-password
 *  transfog-ref-max-cached-features
 *  transfog-ref-refresh-interval
 *  transfog-ref-sequence-url
 * </pre>
 * The class is essentially a wrapper for GFFOntologyReferenceSource, allowing values to be overridden by
 * servlet context parameters.
 *
 * @author  Antony Quinn
 * @version $Id: TransfogReferenceSource.java,v 1.6 2005/05/07 17:13:07 aquinn Exp $
 * @since   1.0
 */
public class TransfogReferenceSource
       extends AbstractDataSource
       implements DazzleReferenceSource, GFFSource, GFFOntologySource {

    // Datasource descriptors
    private static final String DATA_SOURCE_TYPE        = "TransfogReferenceSource";
    private static final String DATA_SOURCE_VERSION     = "1.0";

    // Servlet context parameter names - these can be used to override values in dazzlecfg.xml
    private static final String CTX_URL                 = "transfog-ref-url";
    private static final String CTX_USERNAME            = "transfog-ref-username";
    private static final String CTX_PASSWORD            = "transfog-ref-password";
    private static final String CTX_MAX_CACHED_FEATURES = "transfog-ref-max-cached-features";
    private static final String CTX_REFRESH_INTERVAL    = "transfog-ref-refresh-interval";
    private static final String CTX_SEQUENCE_URL        = "transfog-ref-sequence-url";

    private final GFFOntologyReferenceSource gffSource  = new GFFOntologyReferenceSource();

    /**
     * Set up connections to proxy servers and parse GFF file.
     *
     * @param   servletContext      Servlet context
     * @throws  DataSourceException if could not initialise GFF data source
     * @see     GFFOntologyReferenceSource#init(javax.servlet.ServletContext)
     */
    public void init(ServletContext servletContext) throws DataSourceException {
        super.init(servletContext);
        gffSource.setUrl(getInitParameter(CTX_URL, getUrl()));
        gffSource.setUserName(getInitParameter(CTX_USERNAME, getUserName()));
        gffSource.setPassword(getInitParameter(CTX_PASSWORD, getPassword()));
        gffSource.setMaxCachedFeatures(getInitParameter(CTX_MAX_CACHED_FEATURES, getMaxCachedFeatures()));
        gffSource.setRefreshInterval(getInitParameter(CTX_REFRESH_INTERVAL, getRefreshInterval()));
        String id = getSequenceHolderID();
        SequenceResourceHolder holder = (SequenceResourceHolder) servletContext.getAttribute(id);
        holder.setUrl(getInitParameter(CTX_SEQUENCE_URL, holder.getUrl()));
        gffSource.init(servletContext);
    }

    /* AbstractDataSource overridden methods */

    public int getMinLocation() {
        return gffSource.getMinLocation();
    }

    public void setMinLocation(int minLocation) {
        gffSource.setMinLocation(minLocation);
    }

   /* DazzleReferenceSource interface */

    public Set getEntryPoints() {
        return gffSource.getEntryPoints();
    }

    public String getMapMaster()    {
        return null;
    }

    public Sequence getSequence(String id) throws DataSourceException, NoSuchElementException {
        return gffSource.getSequence(id);
    }

    /* DazzleDataSource interface */

    public Set getAllTypes() {
        return gffSource.getAllTypes();
    }

    public String getDataSourceType()    {
        return DATA_SOURCE_TYPE;
    }

    public String getDataSourceVersion() {
        return DATA_SOURCE_VERSION;
    }

    public String getFeatureID(Feature f) {
        return gffSource.getFeatureID(f);
    }

    public String getFeatureLabel(Feature f) {
        return gffSource.getFeatureLabel(f);
    }

    public List getFeatureNotes(Feature f) {
        return gffSource.getFeatureNotes(f);
    }

    public List getFeatureTargets(Feature f)  {
        return gffSource.getFeatureTargets(f);
    }

    public FeatureHolder getFeatures(String id) throws DataSourceException, NoSuchElementException  {
        return gffSource.getFeatures(id);
    }

    public String getLandmarkVersion(String ref) throws DataSourceException, NoSuchElementException {
        return gffSource.getLandmarkVersion(ref);
    }

    public Map getLinkouts(Feature f)  {
        return gffSource.getLinkouts(f);
    }

    public String getScore(Feature f)   {
        return gffSource.getScore(f);
    }

    public String getSourceDescription(String source)   {
        return gffSource.getSourceDescription(source);
    }

    public String getTypeDescription(String type)   {
        return gffSource.getTypeDescription(type);
    }

    /* GFFSource interface */

    public boolean getDotVersions() {
        return gffSource.getDotVersions();
    }

    public void setDotVersions(boolean b) {
        gffSource.setDotVersions(b);
    }

    public int getMaxCachedFeatures() {
        return gffSource.getMaxCachedFeatures();
    }

    public void setMaxCachedFeatures(int i) {
        gffSource.setMaxCachedFeatures(i);
    }

    public String getSequenceHolderID() {
        return gffSource.getSequenceHolderID();
    }

    public void setSequenceHolderID(String s) {
        gffSource.setSequenceHolderID(s);
    }

    public String getIDAttribute() {
        return gffSource.getIDAttribute();
    }

    /* ConnectionHolder interface */

    public String getPassword() {
        return gffSource.getPassword();
    }

    public void setPassword(String s) {
        gffSource.setPassword(s);
    }

    public String getUserName() {
        return gffSource.getUserName();
    }

    public void setUserName(String s) {
        gffSource.setUserName(s);
    }

    public String getUrl() {
        return gffSource.getUrl();
    }

    public void setUrl(String s) {
        gffSource.setUrl(s);
    }

    /* StreamMonitorHolder interface */

    public int getRefreshInterval() {
        return gffSource.getRefreshInterval();
    }

    public void setRefreshInterval(int i) {
        gffSource.setRefreshInterval(i);
    }

    /* GFFOntologySource interface */

    public String getOntologyMapHolderID() {
        return gffSource.getOntologyMapHolderID();
    }

    public void setOntologyMapHolderID(String id) {
        gffSource.setOntologyMapHolderID(id);
    }

}