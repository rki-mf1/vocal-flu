/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// help message
if (params.help) { exit 0, helpMSG() }

// Parameters sanity checking
Set valid_params = ['cores', 'max_cores', 'memory', 'help',
                    'fasta', 'ref', 'metadata', 'subtype', 
                    'qc', 'split',
                    'output', 'split_dir', 'qc_dir', 'nextclade_dir', 
                    'annot_dir', 'report_dir', 'runinfo_dir',
                    'publish_dir_mode', 'conda_cache_dir',
                    'cloudProcess', 'cloud-process']

def parameter_diff = params.keySet() - valid_params
if (parameter_diff.size() != 0){
    exit 1, "ERROR: Parameter(s) $parameter_diff is/are not valid in the pipeline!\n"
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FLUWARNSYSTEM_SUB }   from '../subworkflows/local/FluWarnSystem_sub'
include { FLUWARNSYSTEM_SPLIT } from '../subworkflows/local/FluWarnSystem_split'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow FLUWARNSYSTEM {

    input_fasta = Channel.fromPath( file("${params.fasta}", checkIfExists: true) )

    rmd = Channel.fromPath( file("bin/report.Rmd", checkIfExists: true) )
    qc_rmd = Channel.fromPath( file("bin/qc-report.Rmd", checkIfExists: true) )

    if (params.metadata != '') {
        metadata = Channel.fromPath( file("${params.metadata}", checkIfExists: true) )
    } else {
        metadata = params.metadata
    }

    if (params.split == ''){

        if (params.subtype == 'h1n1') {
            log.info"INFO: FluWarnSystem is running for Influenza A(H1N1)pdm09"
            if (params.ref == 'old') {
                moc_table = Channel.fromPath( file("data/A(H1N1)pdm09/table_h1n1_moc_HA_California.tsv", checkIfExists: true) )
            } else {
                moc_table = Channel.fromPath( file("data/A(H1N1)pdm09/table_h1n1_moc_HA.tsv", checkIfExists: true) )
            }
            roi_table = Channel.fromPath( file("data/A(H1N1)pdm09/table_h1n1_roi.csv", checkIfExists: true) )
        } else if (params.subtype == 'h3n2') {
            log.info"INFO: FluWarnSystem is running for Influenza A(H3N2)"
            moc_table = Channel.fromPath( file("data/A(H3N2)/table_h3n2_moc_HA.tsv", checkIfExists: true) )
            roi_table = Channel.fromPath( file("data/A(H3N2)/table_h3n2_roi.csv", checkIfExists: true) )
        } else if (params.subtype == 'vic') {
            log.info"INFO: FluWarnSystem is running for Influenza B(Victoria)"
            moc_table = Channel.fromPath( file("data/B(Victoria)/table_vic_moc_HA.tsv", checkIfExists: true) )
            roi_table = Channel.fromPath( file("data/B(Victoria)/table_vic_roi.csv", checkIfExists: true) )
        } else {
            exit 1, 
            "ERROR: $params.subtype is an invalid input for the parameter subtype!\n Please choose between h1n1, h3n2, vic!\n"
        }

        FLUWARNSYSTEM_SUB ( input_fasta, moc_table, roi_table, rmd, qc_rmd, metadata )

    } else if (params.split == 'FluPipe' || 'flupipe' || 'GISAID' || 'gisaid' || 'OpenFlu' || 'openflu') {
        log.info"INFO: FluWarnSystem is running in SPLIT mode $params.split"
        log.info"INFO: Seperate reports for all subtypes in the dataset are generated"

        moc_table_h1n1 = Channel.fromPath( file("data/A(H1N1)pdm09/table_h1n1_moc_HA.tsv", checkIfExists: true) )
        roi_table_h1n1 = Channel.fromPath( file("data/A(H1N1)pdm09/table_h1n1_roi.csv", checkIfExists: true) )

        moc_table_h3n2 = Channel.fromPath( file("data/A(H3N2)/table_h3n2_moc_HA.tsv", checkIfExists: true) )
        roi_table_h3n2 = Channel.fromPath( file("data/A(H3N2)/table_h3n2_roi.csv", checkIfExists: true) )

        moc_table_vic = Channel.fromPath( file("data/B(Victoria)/table_vic_moc_HA.tsv", checkIfExists: true) )
        roi_table_vic = Channel.fromPath( file("data/B(Victoria)/table_vic_roi.csv", checkIfExists: true) )

        FLUWARNSYSTEM_SPLIT ( 
            input_fasta, 
            moc_table_h1n1, roi_table_h1n1,
            moc_table_h3n2, roi_table_h3n2, 
            moc_table_vic, roi_table_vic, 
            rmd, qc_rmd, metadata 
        )

    } else {
        exit 1, 
            "ERROR: $params.split is an invalid input for the parameter split!\n Please choose between FluPipe, GISAID and OpenFlu!\n"
    }

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    HELP
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def helpMSG() {
    c_green = "\033[0;32m";
    c_reset = "\033[0m";
    c_yellow = "\033[0;33m";
    c_blue = "\033[0;34m";
    c_red = "\u001B[31m";
    c_dim = "\033[2m";
    log.info """
    ____________________________________________________________________________________________
    
    ${c_blue}Robert Koch Institute, MF1 Bioinformatics${c_reset}

    Workflow: FluWarnSystem

    ${c_yellow}Usage examples:${c_reset}

    ${c_yellow}Input options:${c_reset}
    ${c_green} --fasta ${c_reset}           REQUIRED! Path to the input fasta file.
                        [ default: $params.fasta ]
    ${c_green} --ref ${c_reset}             If you want to use the recent references from Nextclade, choose ''.
                        H1N1: A/Wisconsin/588/2019 (MW626065)
                        H3N2: A/Darwin/6/2021 (EPI1857216)
                        If you want to use the older references for H1N1 and H3N2, choose 'old'.
                        H1N1: A/California/7/2009 (CY121680)
                        H3N2: A/Wisconsin/67/2005 (CY163680)
                        For Victoria, only B/Brisbane/60/2008 (KX058884) is available.
                        [ default: $params.ref ]                                     
    ${c_green} --metadata ${c_reset}        The path to a metadata file for the sequences with collection dates.
                        Required to generate a heatmap in the report.
                        [ default: $params.metadata ]
    ${c_green} --subtype ${c_reset}         If the input fasta file only contains sequences of one subtype, 
                        define the subtype to choose the right references and tables.
                        Options for Influenza A: 'h1n1' and 'h3n2'
                        Options for Influenza B: 'vic'
                        [ default: $params.subtype ]
    ${c_green} --split ${c_reset}           If the input fasta file contains sequences of more than one subtype, 
                        enable the split parameter to write them into one file per subtype and 
                        ensure the use of the right references and tables.
                        Options: 'FluPipe', 'GISAID' and 'OpenFlu'
                        [ default: $params.split ]
    ${c_green} --qc ${c_reset}              If set to true, a QC report will be generated from the Nextclade output.
                        [ default: $params.qc ]

    ${c_yellow}Computing options:${c_reset}
    --cores                  Max cores per process for local use [default: $params.cores]
    --max_cores              Max cores used on the machine for local use [default: $params.max_cores]
    --memory                 Max memory in GB for local use [default: $params.memory]

    ${c_yellow}Output options:${c_reset}
    --output                 Name of the result folder [default: $params.output]
    --publish_dir_mode       Mode of output publishing: 'copy', 'symlink' [default: $params.publish_dir_mode]
                             ${c_dim}With 'symlink' results are lost when removing the work directory.${c_reset}

    ${c_yellow}Caching:${c_reset}
    --conda_cache_dir        Location for storing the conda environments [default: $params.conda_cache_dir]
    
    ${c_yellow}Execution/Engine profiles:${c_reset}
    The pipeline supports profiles to run via different ${c_green}Executors${c_reset} and ${c_blue}Engines${c_reset} e.g.: -profile ${c_green}local${c_reset},${c_blue}conda${c_reset}
    
    ${c_green}Executor${c_reset} (choose one):
        local
        slurm
    
    ${c_blue}Engines${c_reset} (choose one):
        conda
        mamba
    """
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/