include { NEXTCLADE }   from '../../modules/local/nextclade'
include { PSL }         from '../../modules/local/psl'
include { ANNOTATION }  from '../../modules/local/annotation'
include { REPORT }      from '../../modules/local/report'

workflow FLUWARNSYSTEM_SUB {
    take:
        ref
        input_fasta
        control
        mutation_table
        roi_table
        rmd
        metadata

    main:
        if (params.psl == true) {
            PSL ( ref, input_fasta, control )
            ANNOTATION ( PSL.out.variant_table, mutation_table, roi_table)
        } else if (params.psl == false) {
            NEXTCLADE ( input_fasta, ref )
            ANNOTATION ( NEXTCLADE.out.variant_table, mutation_table, roi_table)
        } else {
            exit 1,
            "ERROR: $params.psl is an invalid input for the parameter psl!\n Please choose between yes/y and no/n!\n"
        }

        REPORT ( ANNOTATION.out.variants_phenotypes, rmd, input_fasta, mutation_table, roi_table, metadata, 'report.html' )

    emit:
        report = REPORT.out.report

}