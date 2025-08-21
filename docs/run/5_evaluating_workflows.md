## So you found a nextflow workflow...

This section maybe needs to be moved to after running_nextflow_locally so that people have more context.

### Evaluating third party nextflow workflows

When you find a third party nextflow workflow, it's important to evaluate whether this workflow will suit your needs. You need to determine:

1. What the inputs and outputs of the workflow are
2. What software the pipeline uses. Is it conda? is it docker/singularity?
3. What the configuration/parameter options are
4. The quality and completeness of the pipeline

For step number 4, here is what you want to look at:

* Does the pipeline have a separate docs page or just a github readme?
* When was the pipeline last updated or released?
* Does the pipeline account for deployment on different platforms, such as HPC and cloud?
* etc

Let's try to go through this process for a few example pipelines

Should we use seqera AI to help configure? Can it be used in the codespace?