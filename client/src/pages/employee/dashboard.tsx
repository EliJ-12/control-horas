import { useAuth } from "@/hooks/use-auth";
import { useWorkLogs, useCreateWorkLog } from "@/hooks/use-work-logs";
import { useAbsences } from "@/hooks/use-absences";
import Layout from "@/components/layout";
import { Clock, Calendar as CalendarIcon, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameDay } from "date-fns";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function EmployeeDashboard() {
  const { user } = useAuth();
  const [open, setOpen] = useState(false);
  const [date, setDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  
  const [view, setView] = useState<"month" | "week">("month");
  const today = new Date();
  const [currentDate, setCurrentDate] = useState(today);
  const monthStart = startOfMonth(currentDate);
  const monthEnd = endOfMonth(currentDate);

  const { data: logs } = useWorkLogs({ 
    userId: user?.id, 
    startDate: format(monthStart, 'yyyy-MM-dd'), 
    endDate: format(monthEnd, 'yyyy-MM-dd') 
  });

  const { data: absences } = useAbsences({ 
    userId: user?.id 
  });

  const createLog = useCreateWorkLog();
  const [regStartTime, setRegStartTime] = useState("09:00");
  const [regEndTime, setRegEndTime] = useState("18:00");
  const [regType, setRegType] = useState<"work" | "absence">("work");

  const days = eachDayOfInterval({ start: monthStart, end: monthEnd });

  const handleFichar = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.id) return;
    
    const [sH, sM] = regStartTime.split(':').map(Number);
    const [eH, eM] = regEndTime.split(':').map(Number);
    const diff = (eH * 60 + eM) - (sH * 60 + sM);

    await createLog.mutateAsync({
      userId: user.id,
      date,
      startTime: regStartTime,
      endTime: regEndTime,
      totalHours: diff > 0 ? diff : 480,
      type: regType
    });
    setOpen(false);
  };

  return (
    <Layout>
      <div className="space-y-8">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Mi Panel</h1>
            <p className="text-muted-foreground">Bienvenido, {user?.fullName}</p>
          </div>

          <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
              <Button size="lg" className="shadow-lg shadow-primary/20">
                <Clock className="mr-2 h-4 w-4" /> Registrar Horas
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Registrar Jornada</DialogTitle>
              </DialogHeader>
              <form onSubmit={handleFichar} className="space-y-4 pt-4">
                <div className="space-y-2">
                  <Label>Tipo de Registro</Label>
                  <Select value={regType} onValueChange={(v: any) => setRegType(v)}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="work">Trabajo</SelectItem>
                      <SelectItem value="absence">Ausencia</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Fecha</Label>
                  <Input type="date" value={date} onChange={e => setDate(e.target.value)} required />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Entrada</Label>
                    <Input type="time" value={regStartTime} onChange={e => setRegStartTime(e.target.value)} required />
                  </div>
                  <div className="space-y-2">
                    <Label>Salida</Label>
                    <Input type="time" value={regEndTime} onChange={e => setRegEndTime(e.target.value)} required />
                  </div>
                </div>
                <Button type="submit" className="w-full">Guardar Registro</Button>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-4">
            <CardTitle>Mi Calendario - {format(currentDate, 'MMMM yyyy')}</CardTitle>
            <div className="flex items-center gap-2">
              <Button 
                variant="outline" 
                size="sm" 
                className={cn(view === "month" && "bg-primary text-primary-foreground")}
                onClick={() => setView("month")}
              >
                Mes
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                className={cn(view === "week" && "bg-primary text-primary-foreground")}
                onClick={() => setView("week")}
              >
                Semana
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-7 gap-px bg-muted rounded-lg overflow-hidden border">
              {['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'].map(d => (
                <div key={d} className="bg-background p-2 text-center text-xs font-medium text-muted-foreground">{d}</div>
              ))}
              {days.map(day => {
                const dayLog = logs?.find(l => isSameDay(new Date(l.date), day));
                const dayAbsence = absences?.find(a => isSameDay(new Date(a.startDate), day));
                const isFichado = dayLog?.type === 'work';
                const isAusencia = dayLog?.type === 'absence' || dayAbsence;
                const isCurrentMonth = day.getMonth() === currentDate.getMonth();

                return (
                  <div key={day.toString()} className={cn(
                    "bg-background min-h-[100px] p-2 border-t relative",
                    !isCurrentMonth && "bg-muted/30"
                  )}>
                    <span className={cn(
                      "text-xs",
                      !isCurrentMonth ? "text-muted-foreground/50" : "text-muted-foreground"
                    )}>{format(day, 'd')}</span>
                    <div className="mt-2 space-y-1">
                      {isFichado && (
                        <div className="text-[10px] bg-emerald-100 text-emerald-700 p-1 rounded border border-emerald-200">
                          {dayLog.startTime} - {dayLog.endTime}
                        </div>
                      )}
                      {isAusencia && (
                        <div className="text-[10px] bg-blue-100 text-blue-700 p-1 rounded border border-blue-200">
                          {dayAbsence ? (dayAbsence.isPartial ? "Ausencia Parcial" : "Ausencia Total") : "Ausencia"}
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      </div>
    </Layout>
  );
}
