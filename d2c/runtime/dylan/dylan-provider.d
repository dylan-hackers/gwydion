provider Dylan {
    probe gf__call__lookup__entry(const char * generic_name);
    probe gf__call__lookup__return(const char * generic_name, const char * method_name);
    probe gf__call__lookup__error(const char * generic_name, const char * error);
};
