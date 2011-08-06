package palindromi;

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

import fi.helsinki.cs.tmc.testrunner.Exercise;
import org.junit.Test;
import static org.junit.Assert.*;

/**
 *
 * @author mrannanj
 */
public class PalindromiTest {

    @Test
    @Points("1.1")
    public void testi1() {
        assertTrue(palindromi.Palindromi.palindromi("a"));
    }

    @Test
    @Points("1.2")
    public void testi2() {
        assertFalse(palindromi.Palindromi.palindromi("ab"));
    }

    @Test
    @Points("1.3")
    public void testi3() {
        assertFalse(palindromi.Palindromi.palindromi("abaa"));
    }

    @Test
    @Points("1.4")
    public void testi4() {
        assertTrue(palindromi.Palindromi.palindromi("abba"));
    }

    @Test
    @Points("1.4")
    public void testi5() {
        assertTrue(palindromi.Palindromi.palindromi("saippuakauppias"));
    }

    @Test
    @Points("1.4")
    public void testi6() {
        assertFalse(palindromi.Palindromi.palindromi("saipxuakauppias"));
    }

    @Test
    @Points("1.5")
    public void testi7() {
        assertTrue(palindromi.Palindromi.palindromi("aba"));
    }

}
