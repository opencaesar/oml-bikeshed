package io.opencaesar.oml2bikeshed

import io.opencaesar.oml.AnnotatedElement
import io.opencaesar.oml.Aspect
import io.opencaesar.oml.AspectReference
import io.opencaesar.oml.Concept
import io.opencaesar.oml.ConceptReference
import io.opencaesar.oml.Description
import io.opencaesar.oml.Graph
import io.opencaesar.oml.NamedElement
import io.opencaesar.oml.ReifiedRelationship
import io.opencaesar.oml.ReifiedRelationshipReference
import io.opencaesar.oml.Relationship
import io.opencaesar.oml.ScalarProperty
import io.opencaesar.oml.ScalarPropertyReference
import io.opencaesar.oml.ScalarRange
import io.opencaesar.oml.ScalarRangeReference
import io.opencaesar.oml.Structure
import io.opencaesar.oml.StructureReference
import io.opencaesar.oml.StructuredProperty
import io.opencaesar.oml.StructuredPropertyReference
import io.opencaesar.oml.Term
import io.opencaesar.oml.TermReference
import io.opencaesar.oml.Terminology
import io.opencaesar.oml.TerminologyExtension
import io.opencaesar.oml.UnreifiedRelationship
import io.opencaesar.oml.UnreifiedRelationshipReference
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource

import static extension io.opencaesar.oml.Oml.*
import static extension io.opencaesar.oml.util.OmlCrossReferencer.*
import io.opencaesar.oml.Entity
import io.opencaesar.oml.Scalar
import io.opencaesar.oml.AnnotationProperty
import java.util.ArrayList
import io.opencaesar.oml.CharacterizableTerm

/**
 * Transform OML to Bikeshed
 * 
 * To produce documentation for a given ontology in OML we use Bikeshed as an intermediate form
 * that can be leveraged to produce the html output from a simpler markdown specificaiton.
 * 
 * See: OML Reference https://opencaesar.github.io/oml-spec/
 * See: Bikeshed Reference https://tabatkins.github.io/bikeshed/
 * 
 */
class OmlToBikeshed {

	val Resource inputResource 
	val String url
	val String relativePath

	new(Resource inputResource, String url, String relativePath) {
		this.inputResource = inputResource
		this.url = url
		this.relativePath = relativePath
	}
	
	def run() {
		inputResource.graph.toBikeshed
	}
	
	private def dispatch String toBikeshed(Graph graph) '''
		<pre class='metadata'>
		«graph.toPre»
		</pre>
		<div export=true>
		«graph.toDiv»
		</div>
	'''
		
	private def String toPre(Graph graph) '''
		Title: «graph.title»
		Shortname: «graph.name»
		Level: 1
		Status: LS-COMMIT
		ED: «url»/«relativePath»
		Repository: «url»
		Editor: «graph.creator»
		!Copyright: «graph.copyright»
		Boilerplate: copyright no, conformance no
		Markup Shorthands: markdown yes
		Use Dfn Panels: yes
		Abstract: «graph.description»
		Favicon: https://opencaesar.github.io/assets/img/oml.png
		!OMLlogo: <img src='https://opencaesar.github.io/assets/img/oml.png' width='50px'/>
	'''

	private def dispatch String toDiv(Terminology terminology) '''
		«terminology.toNamespace("# Namespace # {#heading-namespace}")»			
		«terminology.toImports("# Imports # {#heading-imports}")»
		«terminology.toSubsection(Aspect, "# Aspects # {#heading-aspects}","")»
		«terminology.toSubsection(AspectReference, "# External Aspects # {#heading-external-aspects}","")»
		«terminology.toSubsection(Concept, "# Concepts # {#heading-concepts}","")»
		«terminology.toSubsection(ConceptReference, "# External Concepts # {#heading-external-concepts}","")»
		«terminology.toSubsection(ReifiedRelationship, "# Reified Relationships # {#heading-reifiedrelationships}","")»
		«terminology.toSubsection(ReifiedRelationshipReference, "# External Reified Relationships # {#heading-external-reifiedrelationships}","")»
		«terminology.toSubsection(UnreifiedRelationship, "# Unreified Relationships # {#heading-unreifiedrelationships}","")»
		«terminology.toSubsection(UnreifiedRelationshipReference, "# External Unreified Relationships # {#heading-external-unreifiedrelationships}","")»
		«terminology.toSubsection(Structure, "# Structures # {#heading-structures}","")»
		«terminology.toSubsection(StructureReference, "# External Structures # {#heading-external-structures}","")»
		«terminology.toSubsection(ScalarRange, "# Scalars # {#heading-scalars}","")»
		«terminology.toSubsection(ScalarRangeReference, "# External Structures # {#heading-external-scalars}","")»
		«terminology.toSubsection(StructuredProperty, "# Structured Properties # {#heading-structuredproperties}","")»
		«terminology.toSubsection(StructuredPropertyReference, "# External Structured Properties # {#heading-external-structuredproperties}","")»
		«terminology.toSubsection(ScalarProperty, "# Scalar Properties # {#heading-scalarproperties}","")»
		«terminology.toSubsection(ScalarPropertyReference, "# External Scalar Properties # {#heading-external-scalarproperties}","")»
		«terminology.toSubsection(AnnotationProperty, "# External Annotation Properties # {#heading-external-annotationproperties}","Annotation properties name annotations that can be applied to any AnnotatedElement")»
		
	'''
	
	private def dispatch String toDiv(Description description) '''
		«description.toNamespace("# Namespace # {#heading-namespace}")»
	'''

	// FIXME: this works for internal links to generated docs but not for links to external
	// documentation. 
	private def String toNamespace(Graph graph, String heading) '''
		«heading»
		«val importURI = graph.eResource.URI.trimFileExtension.appendFileExtension('html').lastSegment»
			* «graph.name»: [«graph.iri»](«importURI»)
			
	'''
	
	private def String toImports(Terminology terminology, String heading) '''
		«heading»
		*Extensions:*
		«FOR _extension : terminology.imports.filter(TerminologyExtension)»
		«val importURI = URI.createURI(_extension.importURI).trimFileExtension.appendFileExtension('html')»
			* «_extension.importAlias»: [«_extension.importedGraph.iri»](«importURI»)
		«ENDFOR»
	'''

	private def <T extends AnnotatedElement> String toSubsection(Terminology terminology, Class<T> type, String heading, String text) '''
		«val elements = terminology.statements.filter(type)»
		«IF !elements.empty»
		«heading»
		
		«text»
		
		«FOR element : elements»
		«element.toBikeshed»
		
		«ENDFOR»
		«ENDIF»
	'''

	private def dispatch String toBikeshed(Term term) '''
		«term.sectionHeader»
		
		«term.comment»
		
		«term.plainDescription»
		
		«val superTerms = term.specializedTerms»
		«IF !superTerms.empty»

		*Super terms:*
		«superTerms.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(term.graph)»</a>'''].join(', ')»
		«ENDIF»
		«val subTerms = term.allSpecializingTerms»
		«IF !subTerms.empty»

		*Sub terms:*
		«subTerms.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(term.graph)»</a>'''].join(', ')»
		«ENDIF»
		
	'''

	private def dispatch String toBikeshed(Entity entity) '''
		«entity.sectionHeader»
		
		«entity.comment»
		
		«entity.plainDescription»
		
		«val superEntities = entity.specializedTerms»
		«IF !superEntities.empty»

		*Super entities:*
		«superEntities.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»
		«val subEntities = entity.allSpecializingTerms.filter(Entity)»
		«IF !subEntities.empty»

		*Sub entities:*
		«subEntities.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»

		«val domainRelations = entity.allSourceReifiedRelations»
		«IF !domainRelations.empty»
		*Relations having «entity.localName» as domain:*
		«domainRelations.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»
		
		«val rangeRelations = entity.allTargetReifiedRelations»
		«IF !rangeRelations.empty»
		*Relations having «entity.localName» as range:*
		«rangeRelations.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»

		«val properties = entity.allDomainProperties»
		«IF !properties.empty»
		*Direct Properties:*
		«properties.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»
		
		«val transitiveproperties = entity.specializedTerms.filter(CharacterizableTerm).map(e | e.allDomainProperties).flatten»
		«IF !transitiveproperties.empty»
		*Supertype Properties:*
		«transitiveproperties.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»
	'''
	
	private def String getRelationshipAttributes(Relationship relationship) {
		val ArrayList<String> pnames=new ArrayList
		if (relationship.functional) pnames.add("Functional")
		if (relationship.inverseFunctional) pnames.add("InverseFunctional")
		if (relationship.symmetric) pnames.add("Symmetric")
		if (relationship.asymmetric) pnames.add("Asymmetric")
		if (relationship.reflexive) pnames.add("Reflexive")
		if (relationship.irreflexive) pnames.add("Irreflexive")
		if (relationship.transitive) pnames.add("Transitive")
		pnames.join(", ")
	}
	
	private def String toBikeshedHelper(Relationship relationship) '''
		
		«val attr=relationship.relationshipAttributes»
		«IF attr !== null»
		*Attributes:* «attr»
		«ENDIF»
		
		*Source:*
		«val source = relationship.source»
		<a spec="«source.graph.iri»" lt="«source.name»">«source.getReferenceName(relationship.graph)»</a>

		*Target:*
		«val target = relationship.target»
		<a spec="«target.graph.iri»" lt="«target.name»">«target.getReferenceName(relationship.graph)»</a>

		*Forward:*
		<dfn attribute for=«relationship.name»>«relationship.forward.name»</dfn>
		«relationship.forward.description»
		«IF relationship.inverse !== null»

		*Inverse:*
		<dfn attribute for=«relationship.name»>«relationship.inverse.name»</dfn>
		«relationship.inverse.description»
		«ENDIF»
		«val superTerms = relationship.specializedTerms»
		«IF !superTerms.empty»

		*Super terms:*
		«superTerms.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(relationship.graph)»</a>'''].join(', ')»
		«ENDIF»
		«val subTerms = relationship.allSpecializingTerms»
		«IF !subTerms.empty»

		*Sub terms:*
		«subTerms.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(relationship.graph)»</a>'''].join(', ')»
		«ENDIF»
	'''

	private def dispatch String toBikeshed(ReifiedRelationship relationship) '''
		«relationship.sectionHeader»
	
		«relationship.comment»
		
		«relationship.plainDescription»
		
		«relationship.toBikeshedHelper»
		
		«val properties = relationship.allDomainProperties»
		«IF !properties.empty»
		*Direct Properties:*
		«properties.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(relationship.graph)»</a>'''].join(', ')»
		«ENDIF»
		
		«val transitiveproperties = relationship.specializedTerms.filter(CharacterizableTerm).map(e | e.allDomainProperties).flatten»
		«IF !transitiveproperties.empty»
		*Supertype Properties:*
		«transitiveproperties.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(relationship.graph)»</a>'''].join(', ')»
		«ENDIF»
	'''
	
	// Can ordinary relationships have descriptions too?
	private def dispatch String toBikeshed(Relationship relationship) '''
	
		«relationship.sectionHeader»
		
		«relationship.comment»
		
		«relationship.plainDescription»
		
		«relationship.toBikeshedHelper»
	'''
	
	
  //TODO: find an ontology containing examples of this we can test against
	private def dispatch String toBikeshed(StructuredProperty property) '''
		«property.sectionHeader»
		
		«property.comment»
		
		«property.plainDescription»
		
	'''
	
	private def dispatch String toBikeshed(ScalarProperty property) '''
		«property.sectionHeader»
		
		«property.comment»
		
		«property.plainDescription»
		
		«val range = property.range»
		
		Scalar property type: <a spec="«range.graph?.iri»" lt="«range.name»">«range.getReferenceName(range.graph)»</a>
		
	'''
	
	private def dispatch String toBikeshed(AnnotationProperty property) '''
		«property.sectionHeader»
		
		«property.comment»

		«property.plainDescription»
		
	'''
	
	private def dispatch String toBikeshed(TermReference reference) '''
		«val term = reference.resolve»
		## <a spec="«term.graph.iri»" lt="«term.name»">«reference.localName»</a> ## {#heading-«reference.localName»}
		«reference.comment»
		«val superTerms = reference.specializedTerms»
		«IF !superTerms.empty»

		*Super terms:*
		«superTerms.sortBy[name].map['''<a spec="«graph.iri»">«name»</a>'''].join(', ')»
		«ENDIF»
		
	'''

	private def dispatch String toBikeshed(Scalar property) '''
		«property.sectionHeader»
		
		«property.comment»
		
		«property.plainDescription»
		
	'''
	
	//----------------------------------------------------------------------------------------------------------

	private def String getPlainDescription(Term term) {
		val desc=term.description
		if (desc.startsWith("http")) ""
		else 
			desc
	}
	
	/**
	 * Tricky bit: if description starts with a url we treat it as an
	 * external definition.
	 */
	private def String getSectionHeader(Term term) {
		val desc=term.description
		
		if (desc.startsWith("http"))
		'''## <dfn>«term.name»</dfn> see \[«term.localName»](«desc») ## {#heading-«term.localName»}'''
		else
		'''## <dfn>«term.name»</dfn> ## {#heading-«term.localName»}'''
	}
	
	private def String getTitle(NamedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/title", element.name?:"")
	}
	
	private def String getDescription(AnnotatedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/description", "")
	}
	
	private def String getDescriptionURL(AnnotatedElement element) {
		val desc = element.description
		if (desc.startsWith("http")) '''
			[«element.localName»](«desc»)
		'''
		else
			desc
	}

	private def String getCreator(AnnotatedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/creator", "Unknown")
	}

	private def String getCopyright(AnnotatedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/rights", "").replaceAll('\n', '')
	}
	
	private def String getRelation(AnnotatedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/relation", "").replaceAll('\n', '')
	}

	private def String getComment(AnnotatedElement element) {
		element.getAnnotationStringValue("http://www.w3.org/2000/01/rdf-schema#comment", "")
	}
	
	private def String getSeeAlso(AnnotatedElement element) {
		element.getAnnotationStringValue("http://www.w3.org/2000/01/rdf-schema#seeAlso", "")
	}
	
	private def String getReferenceName(NamedElement referenced, Graph graph) {
		val localName = referenced.getLocalNameIn(graph)
		localName ?: referenced.qualifiedName
	}
}