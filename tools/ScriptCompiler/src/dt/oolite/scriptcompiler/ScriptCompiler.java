/*
 * Oolite script compiler.
 * 
 * Copyright (c) 2006 David Taylor. All rights reserved.
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License.
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/
 * or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
 *
 * You are free:
 *
 * o to copy, distribute, display, and perform the work
 * o to make derivative works
 *
 * Under the following conditions:
 *
 * o Attribution. You must give the original author credit.
 * o Noncommercial. You may not use this work for commercial purposes.
 * o Share Alike. If you alter, transform, or build upon this work,
 *   you may distribute the resulting work only under a license identical to this one.
 *
 * For any reuse or distribution, you must make clear to others the license terms of this work.
 * Any of these conditions can be waived if you get permission from the copyright holder.
 * Your fair use and other rights are in no way affected by the above.
 */
package dt.oolite.scriptcompiler;

import java.io.*;
import java.util.*;

public class ScriptCompiler {

    private static int indent = -4;
/*
 * TODO: fix this to handle else properly, and also use then and endif rather than braces.
 * 
    private static void printConditionAndActions(HashMap script) {
        indent += 4;
        String indentString = "";
        for (int i = 0; i < indent; i++)
            indentString += " ";

        String secondIndent = indentString + "    ";

        ArrayList conditions = (ArrayList)script.get("conditions");
        ArrayList actions = (ArrayList)script.get("do");
        ArrayList elses = (ArrayList)script.get("else");
        if (conditions.size() > 0) {
            System.out.print(indentString + "if ");

            for (int i = 0; i < conditions.size(); i++) {
                if (i > 0)
                    System.out.print(" and ");

                System.out.print("( " + conditions.get(i) + " )");
            }

            System.out.println(" then {");
        } else {
            System.out.println(indentString + "always {");
        }

        if (actions.size() > 0) {
            for (int i = 0; i < actions.size(); i++) {
                Object o = actions.get(i);
                if (o instanceof HashMap)
                    printConditionAndActions((HashMap)o);
                else if (o instanceof String)
                    System.out.println(secondIndent + o);
            }
            System.out.println(indentString + "}");
        } else {
            System.out.println(indentString + "}");
        }

        if (elses != null && elses.size() > 0) {
            System.out.println(indentString + "else {");
            for (int i = 0; i < elses.size(); i++) {
                Object o = elses.get(i);
                if (o instanceof HashMap)
                    printConditionAndActions((HashMap)o);
                else if (o instanceof String)
                    System.out.println(secondIndent + o);
            }
            System.out.println(indentString + "}");
        } else {
            System.out.println(indentString + "}");
        }

        indent -= 4;
    }
*/
    /**
     * Returns a string containing the compiled script in XML Plist format.
     * 
     * @param script a HashMap containing a compiled Oolite script
     * @return a string containing the compiled script in XML Plist format  
     */
    public static String compiledScriptToXML(HashMap script) {
        StringBuffer plist = new StringBuffer("");
        plist.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        plist.append("<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
        plist.append("<plist version=\"1.0\">\n");

        plist.append(hashMapToXML(script));
        plist.append("</plist>\n");
        return plist.toString();
    }

    /**
     * Transform an ArrayList to XML PList format, using the index order.
     * 
     * @param array the ArrayList to export
     * @return a string containing an XML PList represnetation of array
     */
    public static String arrayListToXML(ArrayList array) {
        indent += 4;
        String indentString = "";
        for (int i = 0; i < indent; i++)
            indentString += " ";

        String secondIndent = indentString + "    ";

        StringBuffer sb = new StringBuffer(8192);
        sb.append(indentString + "<array>\n");
        
        for (Iterator iter = array.iterator(); iter.hasNext();) {
            Object element = iter.next();
            if (element instanceof ArrayList)
                sb.append(arrayListToXML((ArrayList)element));
            else if (element instanceof HashMap)
                sb.append(conditionalHashMapToXML((HashMap)element));
            else
                sb.append(secondIndent + "<string>" + element.toString() + "</string>\n");
        }

        sb.append(indentString + "</array>\n");

        indent -=4;
        return sb.toString();
    }

    /**
     * Transform a HashMap to XML PList format, using whatever order the
     * keys are give by the iterator.
     * 
     * @param map the HashMap to export
     * @return a string containing an XML PList represnetation of map 
     */
    public static String hashMapToXML(HashMap map) {
        indent += 4;
        String indentString = "";
        for (int i = 0; i < indent; i++)
            indentString += " ";

        String secondIndent = indentString + "    ";

        StringBuffer sb = new StringBuffer(8192);
        sb.append(indentString + "<dict>\n");

        Set keys = map.keySet();
        for (Iterator iter = keys.iterator(); iter.hasNext();) {
            String key = (String)iter.next();
            sb.append(secondIndent + "<key>" + key + "</key>\n");

            Object element = map.get(key);
            if (element instanceof ArrayList)
                sb.append(arrayListToXML((ArrayList)element));
            else if (element instanceof HashMap)
                sb.append(conditionalHashMapToXML((HashMap)element));
            else
                sb.append(secondIndent + "<string>" + element.toString() + "</string>\n");
        }

        sb.append(indentString + "</dict>\n");

        indent -=4;
        return sb.toString();
    }

    /**
     * Transform a HashMap to XML PList format, assuming it contains
     * Oolite script conditions/do/else information.
     *
     * This assumption means there must be two or three keys, "conditions",
     * "do", and optionally "else. The data for each of those keys must be
     * an ArrayList.
     * 
     * @param map the HashMap to export
     * @return a string containing an XML PList represnetation of map 
     */
    public static String conditionalHashMapToXML(HashMap map) {
        indent += 4;
        String indentString = "";
        for (int i = 0; i < indent; i++)
            indentString += " ";

        String secondIndent = indentString + "    ";

        StringBuffer sb = new StringBuffer(8192);
        sb.append(indentString + "<dict>\n");

        String key = "conditions";
        ArrayList conditions = (ArrayList)map.get(key);
        if (conditions != null) {
            sb.append(secondIndent + "<key>" + key + "</key>\n");
            sb.append(arrayListToXML(conditions));
        }

        key = "do";
        ArrayList dos = (ArrayList)map.get(key);
        if (dos != null) {
            sb.append(secondIndent + "<key>" + key + "</key>\n");
            sb.append(arrayListToXML(dos));
        }

        key = "else";
        ArrayList elses = (ArrayList)map.get(key);
        if (elses != null) {
            sb.append(secondIndent + "<key>" + key + "</key>\n");
            sb.append(arrayListToXML(elses));
        }

        sb.append(indentString + "</dict>\n");

        indent -=4;
        return sb.toString();
    }

    /**
     * Compile an Oolite script into the in-memory representation of HashMaps, ArrayLists, and Strings.
     * 
     * @param script the complete script
     * @return a HashMap representing the "script" dictionary of the script PList file 
     */
    public static HashMap compileScript(String script) {
        HashMap m = new HashMap();

        ByteArrayInputStream is = new ByteArrayInputStream(script.getBytes());
        Reader r = new BufferedReader(new InputStreamReader(is));
        StreamTokenizer st = new StreamTokenizer(r);
        st.wordChars('_', '_'); // is just another "letter"
        st.wordChars(':', ':'); // is just another "letter"
        st.wordChars('!', '!'); // is just another "letter"
        st.wordChars('@', '@'); // is just another "letter"
        st.wordChars('[', '['); // is just another "letter"
        st.wordChars(']', ']'); // is just another "letter"
        //st.wordChars('{', '{'); // is just another "letter"
        //st.wordChars('}', '}'); // is just another "letter"
        st.wordChars('=', '='); // is just another "letter"
        st.wordChars('<', '<'); // is just another "letter"
        st.wordChars('>', '>'); // is just another "letter"

        st.ordinaryChars('0', '9'); // not interested in numbers as numbers, just as words
        st.wordChars('0', '9'); // not interested in numbers as numbers, just as words
        st.wordChars('.', '.'); // not interested in numbers as numbers, just as words
        st.wordChars('-', '-'); // not interested in numbers as numbers, just as words
        st.eolIsSignificant(true);
        st.slashSlashComments(true);
        st.slashStarComments(true);

        ArrayList a = new ArrayList();
        try {
            st.nextToken();
            String scriptName = st.sval;

            while (true) {
                st.nextToken();
                if (st.ttype == StreamTokenizer.TT_EOF)
                    break;

                if (st.ttype == StreamTokenizer.TT_EOL)
                    continue;

                if (st.ttype != StreamTokenizer.TT_WORD)
                    throw new RuntimeException("A");
                
                if (st.sval.equals("if") != true)
                    throw new RuntimeException("B");

                m.put(scriptName, a);
                parseIf(a, st);
            }
            
            r.close();
            is.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return m;
    }

    /**
     * Parse an "if" statement, generating a HashMap from it and adding that
     * to the given ArrayList.
     * 
     * @param array an ArrayList representing the parent of the "if" statement
     * @param st a StreamTokenizer already initialised, and whose last token was "if"
     * @throws IOException if anything bad happens
     */
    public static void parseIf(ArrayList array, StreamTokenizer st) throws IOException {
        HashMap m = new HashMap(3);
        ArrayList conditions = new ArrayList();
        ArrayList actions = new ArrayList();
        StringBuffer statement = new StringBuffer(80);
        String s;
        boolean needMoreStatements = true;
        boolean inElse = false;

        while (true) {
            st.nextToken();
            if (st.ttype == StreamTokenizer.TT_EOL)
                continue; // ignore EOLs in if statements

            if (st.ttype == StreamTokenizer.TT_EOF)
                throw new RuntimeException("C");
            
            if (st.sval.equalsIgnoreCase("then")) {
                s = statement.toString().trim();
                if (s.length() < 1)
                    throw new RuntimeException("D1");

                conditions.add(s);
                statement = new StringBuffer(80);
                break;
            }

            if (st.sval.equalsIgnoreCase("and")) {
                s = statement.toString().trim();
                if (s.length() < 1)
                    throw new RuntimeException("D2");

                conditions.add(s);
                statement = new StringBuffer(80);
                continue;
            }

            String token = st.sval;
            if (token.equals("="))
                token = "equal";
            if (token.equals("<"))
                token = "lessthan";
            if (token.equals(">"))
                token = "greaterthan";

            statement.append(token + " ");
        }

        m.put("conditions", conditions);

        while (needMoreStatements) {
            while (true) {
                st.nextToken();
                if (st.ttype == StreamTokenizer.TT_EOL) {
                    s = statement.toString().trim();
                    if (s.length() > 0) {
                        actions.add(s);
                        statement = new StringBuffer(80);
                    }
                    continue;
                }

                if (st.ttype == StreamTokenizer.TT_EOF)
                    throw new RuntimeException("E");

                if (st.sval.equals("if")) {
                    s = statement.toString().trim();
                    if (s.length() > 0) {
                        actions.add(s);
                        statement = new StringBuffer(80);
                    }

                    parseIf(actions, st);
                    continue;
                }

                if (st.sval.equalsIgnoreCase("else")) {
                    if (inElse)
                        throw new RuntimeException("F");

                    s = statement.toString().trim();
                    if (s.length() > 0) {
                        actions.add(s);
                        statement = new StringBuffer(80);
                    }

                    // Now close off the "true" actions array and create
                    // the "else" actions array.
                    m.put("do", actions);
                    actions = new ArrayList();
                    inElse = true;
                    break;
                }

                if (st.sval.equalsIgnoreCase("endif")) {
                    s = statement.toString().trim();
                    if (s.length() > 0) {
                        actions.add(s);
                        statement = new StringBuffer(80);
                    }

                    if (inElse)
                        m.put("else", actions);
                    else
                        m.put("do", actions);

                    needMoreStatements = false;
                    break;
                }
    
                statement.append(st.sval + " ");
            }
        }

        array.add(m);
    }

    /**
     * This main method takes the name of an Oolite script file (.oos) and converts
     * it to an XML plist file with the same name in the same directory.
     *
     * @param args the filename of the script to convert to XML
     */
    public static void main(String[] args) {
        // for testing
        String filename = "C:/Program Files/Oolite/AddOns/dajt.oxp/Config/script.oos";
        
        System.out.println("Oolite script compiler");
        System.out.println("Copyright 2006 David Taylor. All rights reserved.");

        if (args.length > 0)
            filename = new String(args[0]);
        else {
            System.out.println("Usage: java dt.oolite.scriptcompiler.ScriptCompiler scriptfile");
            System.exit(1);
        }

        if (filename.endsWith(".oos") != true) {
            System.out.println("The script file must have an extension of .oos");
            System.exit(1);            
        }

        String xmlFilename = filename.replaceAll(".oos$", ".plist");
        System.out.println("transforming " + filename);
        System.out.println("to " + xmlFilename);

        try {
            BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(filename)));
            StringBuffer sb = new StringBuffer(8192);
            while (true) {
                String s = br.readLine();
                if (s == null)
                    break;
                sb.append(s + "\r\n");
            }
            br.close();

            HashMap m = compileScript(sb.toString());
            String xml = compiledScriptToXML(m);

            OutputStream fos = new FileOutputStream(xmlFilename);
            fos.write(xml.getBytes());
            fos.flush();
            fos.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
