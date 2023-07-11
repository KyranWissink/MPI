# -*- coding: utf-8 -*-
"""
Created on Thu Jan 12 11:02:00 2023

@author: Kyran Wissink
"""

# Set the config file as initialised by init.py
configfile: "config.yaml"

# Extract sample name from config file
sample_name = config["sample"].split("/")[-1]

# Define output directory
output_dir = "output/" + config["runid"] + "/"

# Define sorted data directory
sorted_data_dir = "sorted_data/" + config["runid"] + "/" + sample_name

# Define pggb output directory
pggb_output_dir = output_dir + "pggb_out"


# Final output rule
rule all:
    input:
        output_dir + "multiqc_report.html"
    shell:
        """
        cp config.yaml {output_dir}
        zip -m {output_dir}snake_out.zip {output_dir}config.yaml {output_dir}coreness_stats.csv {output_dir}data.gfa {output_dir}heatmap.png {output_dir}multiqc_config.yaml
        """


# Moves the input data to a new directory and uses samtools to index it
rule sort_data:
    input:
        config["sample"]
    output:
        sorted_data_dir
    shell:
        """
        cp {input} {output}
        samtools faidx {output}
        """


# Runs pggb with all the parameters either supplied or generated
rule pggb:
    input:
        sorted_data_dir
    output:
        directory(pggb_output_dir)
    params:
        haplotypes = config["pggb"]["haplotypes"],
        segment_length = config["pggb"]["segment_length"],
        poa_params = config["pggb"]["poa_params"],
        percent_identity = config["pggb"]["percent_identity"],
        threads = config["pggb"]["threads"]
    shell:
        """
        pggb --input-fasta {input} \
        --threads {params.threads} \
        -n {params.haplotypes} \
        -p {params.percent_identity} \
        --segment-length {params.segment_length} \
        --poa-params {params.poa_params} \
        --output-dir {pggb_output_dir}
        """


# Move pggb output files to pggb directory
rule move_files:
    input:
        pggb_output_dir
    output:
        output_dir + "data.gfa"
    shell:
        """
        mv {input}/*fix.gfa {output}
        """


# Produce GFA graph
rule produce_gfa_graph:
    input:
        output_dir + "data.gfa"
    output:
        output_dir + "coreness_stats.csv"
    shell:
        """
        python3 scripts/gfa.py {input} {output_dir}
        """


# Generate MultiQC report
rule generate_multiqc_report:
    input:
        output_dir + "coreness_stats.csv"
    output:
        output_dir + "multiqc_report.html"
    shell:
        """
        cp multiqc_config.yaml {output_dir}
        multiqc -f {output_dir} -o {output_dir}
        """

