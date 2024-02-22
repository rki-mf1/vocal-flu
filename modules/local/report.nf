process REPORT {
    label 'report'

    publishDir "${params.output}/${params.report_dir}", mode: params.publish_dir_mode

    input:
        path variant_table
        path variants_phenotypes
        path rmd
        path input_fasta
        path moc_table
        path roi_table
        val metadata
        val subtype
        val output

    output:
        path "fluwarnsystem-alerts-samples-all.csv",                emit: alerts_samples
        path "fluwarnsystem-alerts-clusters-summaries-all.csv",     emit: alerts_clusters
        path "${output}",                                           emit: report

    script:
    """
    echo "Step 3: Detect and alert emerging variants"

    prepare_report.R \
        -f ${variants_phenotypes} \
        -s "fluwarnsystem-alerts-samples-all.csv" \
        -c "fluwarnsystem-alerts-clusters-summaries-all.csv"

    Rscript --vanilla -e \
        "rmarkdown::render(input = \'${rmd}\', \\
        output_file = \'${output}\', \\
        params = list(
            fasta = \'${input_fasta}\', \\
            metadata = \'${metadata}\', \\
            variant_table = \'${variant_table}\', \\
            annot_table = \'${variants_phenotypes}\', \\
            alert_samples = \'fluwarnsystem-alerts-samples-all.csv\', \\
            subtype = \'${subtype}\', \\
            ref = \'${params.ref}\', \\
            moc = \'${moc_table}\', \\
            roi = \'${roi_table}\')
        )"
    """

    stub:
    """
    touch fluwarnsystem-alerts-samples-all.csv 
    touch fluwarnsystem-alerts-clusters-summaries-all.csv 
    touch report.html 
    touch report-h1n1.html
    touch report-h3n2.html
    touch report-vic.html
    """
}